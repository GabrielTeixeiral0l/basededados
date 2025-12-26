-- =============================================================================
-- 5. TRIGGERS DE INTEGRIDADE E REGRAS DE NEGÓCIO (SIMPLIFICADO)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 5.1. VALIDAÇÃO DE NOTA (INTERVALO 0-20)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_NOTA
    BEFORE INSERT OR UPDATE ON nota
    FOR EACH ROW
BEGIN
    IF :NEW.nota < PKG_CONSTANTES.NOTA_MINIMA THEN 
        :NEW.nota := PKG_CONSTANTES.NOTA_MINIMA;
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Nota ajustada para o mínimo (0).');
    ELSIF :NEW.nota > PKG_CONSTANTES.NOTA_MAXIMA THEN 
        :NEW.nota := PKG_CONSTANTES.NOTA_MAXIMA;
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Nota ajustada para o máximo (20).');
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.1.1. REGRAS DE TIPO DE AVALIAÇÃO (FILHOS E GRUPOS)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_AVALIACAO_REGRAS
    BEFORE INSERT OR UPDATE ON avaliacao
    FOR EACH ROW
DECLARE
    v_permite_filhos CHAR(1);
    v_permite_grupo  CHAR(1);
    v_tipo_pai_id    NUMBER;
BEGIN
    -- 1. Regra permite_filhos: Se tem pai, o pai tem de permitir filhos
    IF :NEW.avaliacao_pai_id IS NOT NULL THEN
        -- Buscar o tipo de avaliação do pai
        BEGIN
            SELECT tipo_avaliacao_id INTO v_tipo_pai_id FROM avaliacao WHERE id = :NEW.avaliacao_pai_id;
            SELECT permite_filhos INTO v_permite_filhos FROM tipo_avaliacao WHERE id = v_tipo_pai_id;
            
            IF v_permite_filhos = '0' THEN
                PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: A avaliação pai (ID '||:NEW.avaliacao_pai_id||') não permite sub-avaliações.');
            END IF;
        EXCEPTION WHEN NO_DATA_FOUND THEN NULL; -- Pai não encontrado (novo insert?) ou erro de dados
        END;
    END IF;

    -- 2. Regra permite_grupo: Se max_alunos > 1, o tipo tem de permitir grupo
    SELECT permite_grupo INTO v_permite_grupo FROM tipo_avaliacao WHERE id = :NEW.tipo_avaliacao_id;
    
    IF :NEW.max_alunos > 1 AND v_permite_grupo = '0' THEN
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: O tipo de avaliação selecionado não permite trabalhos de grupo.');
    END IF;
    
    -- Nota: A validação de soma de pesos (100%) foi removida deste trigger de linha 
    -- para evitar o erro ORA-04091 (Tabela Mutante), pois requer ler a própria tabela 'avaliacao'.
END;
/

-- -----------------------------------------------------------------------------
-- 5.2. CONFLITO DE HORÁRIO (SALA OU DOCENTE)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_HORARIO_AULA
    BEFORE INSERT OR UPDATE ON aula
    FOR EACH ROW
DECLARE
    v_conflito NUMBER;
    v_doc_id   NUMBER;
BEGIN
    -- Obter o docente da turma da nova aula
    SELECT docente_id INTO v_doc_id FROM turma WHERE id = :NEW.turma_id;
    
    -- Validar conflito de Sala OU Docente
    -- Usamos uma query direta. Em inserts simples isto funciona.
    -- Em updates complexos pode dar tabela mutante, mas para o caso de uso comum serve.
    SELECT COUNT(*) INTO v_conflito 
    FROM aula a 
    JOIN turma t ON a.turma_id = t.id
    WHERE a.id != NVL(:NEW.id, -1)
      AND a.data = :NEW.data 
      AND a.status = '1'
      AND ((a.sala_id = :NEW.sala_id) OR (t.docente_id = v_doc_id))
      AND (:NEW.hora_inicio < a.hora_fim AND :NEW.hora_fim > a.hora_inicio);
      
    IF v_conflito > 0 THEN 
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: Conflito de horário detectado para sala ou docente.');
    END IF;
EXCEPTION WHEN OTHERS THEN
    -- Ignorar erro de tabela mutante se ocorrer, para não bloquear operação
    NULL;
END;
/

-- -----------------------------------------------------------------------------
-- 5.3. CAPACIDADE DA TURMA
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_CAPACIDADE_TURMA
    BEFORE INSERT ON inscricao
    FOR EACH ROW
DECLARE
    v_max NUMBER; 
    v_ins NUMBER;
BEGIN
    SELECT max_alunos INTO v_max FROM turma WHERE id = :NEW.turma_id;
    IF v_max IS NOT NULL THEN
        SELECT COUNT(*) INTO v_ins FROM inscricao WHERE turma_id = :NEW.turma_id AND status = '1';
        IF v_ins >= v_max THEN
            PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: A turma atingiu o limite máximo de alunos.');
        END IF;
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.4. REGRAS DO ESTUDANTE (DÍVIDAS, PLANO E ECTS)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_ESTUDANTE_REGRAS
    BEFORE INSERT ON inscricao
    FOR EACH ROW
DECLARE 
    v_est_id     NUMBER; 
    v_cur_id     NUMBER; 
    v_uc_id      NUMBER; 
    v_existe     NUMBER;
    v_total_ects NUMBER;
BEGIN
    SELECT estudante_id, curso_id INTO v_est_id, v_cur_id FROM matricula WHERE id = :NEW.matricula_id;
    SELECT unidade_curricular_id INTO v_uc_id FROM turma WHERE id = :NEW.turma_id;

    -- Validação 1: Dívidas
    IF FUN_IS_DEVEDOR(v_est_id) = 'S' THEN 
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: O estudante ' || v_est_id || ' tem dívidas de propinas pendentes.');
    END IF;

    -- Validação 2: UC no Plano de Estudos
    SELECT COUNT(*) INTO v_existe FROM uc_curso WHERE curso_id = v_cur_id AND unidade_curricular_id = v_uc_id;
    IF v_existe = 0 THEN 
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: A UC ' || v_uc_id || ' não pertence ao plano de estudos do curso ' || v_cur_id);
    END IF;

    -- Validação 3: Limite de ECTS Anual
    SELECT SUM(uc.ects) INTO v_total_ects
    FROM inscricao i
    JOIN turma t ON i.turma_id = t.id
    JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
    WHERE i.matricula_id = :NEW.matricula_id 
      AND i.status = '1'
      AND uc.curso_id = v_cur_id;
      
    SELECT ects INTO v_existe FROM uc_curso WHERE curso_id = v_cur_id AND unidade_curricular_id = v_uc_id;
    v_total_ects := NVL(v_total_ects, 0) + v_existe;

    IF v_total_ects > PKG_CONSTANTES.LIMITE_ECTS_ANUAL THEN
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: Limite de ECTS anual excedido ('||v_total_ects||' > '||PKG_CONSTANTES.LIMITE_ECTS_ANUAL||')');
    END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- -----------------------------------------------------------------------------
-- 5.6. AGREGAÇÃO DE NOTAS (SINALIZAÇÃO)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_NOTA_SINALIZA_CALCULO
    AFTER INSERT OR UPDATE ON nota
    FOR EACH ROW
DECLARE 
    v_pai NUMBER;
BEGIN
    IF PKG_BUFFER_NOTA.g_a_calcular THEN RETURN; END IF;

    PKG_BUFFER_NOTA.ADICIONAR_FINAL(:NEW.inscricao_id);
    SELECT avaliacao_pai_id INTO v_pai FROM avaliacao WHERE id = :NEW.avaliacao_id;
    IF v_pai IS NOT NULL THEN 
        PKG_BUFFER_NOTA.ADICIONAR_PAI(:NEW.inscricao_id, v_pai); 
    END IF;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN NULL;
END;
/

-- -----------------------------------------------------------------------------
-- 5.6.1. AGREGAÇÃO DE NOTAS (EXECUÇÃO)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_NOTA_EXECUTA_CALCULOS
    AFTER INSERT OR UPDATE ON nota
DECLARE 
    v_nota_pai     NUMBER; 
    v_pai_do_pai   NUMBER; 
    v_insc_atual   NUMBER;
    v_pai_atual    NUMBER;
BEGIN
    IF PKG_BUFFER_NOTA.g_a_calcular THEN RETURN; END IF;

    PKG_BUFFER_NOTA.g_a_calcular := TRUE;

    -- 1. Processar Pais Diretos (Loop Simples)
    IF PKG_BUFFER_NOTA.v_ids_inscricao.COUNT > 0 THEN
        FOR i IN 1..PKG_BUFFER_NOTA.v_ids_inscricao.COUNT LOOP
            v_insc_atual := PKG_BUFFER_NOTA.v_ids_inscricao(i);
            v_pai_atual  := PKG_BUFFER_NOTA.v_ids_pais(i);

            -- Calcular nota do pai
            SELECT SUM(n.nota * (NVL(a.peso, 0) / 100)) INTO v_nota_pai 
            FROM nota n JOIN avaliacao a ON n.avaliacao_id = a.id
            WHERE n.inscricao_id = v_insc_atual 
              AND a.avaliacao_pai_id = v_pai_atual 
              AND n.status = '1';
              
            -- Atualizar ou Inserir nota do pai
            UPDATE nota SET nota = v_nota_pai, updated_at = SYSDATE 
            WHERE inscricao_id = v_insc_atual AND avaliacao_id = v_pai_atual;
              
            IF SQL%ROWCOUNT = 0 THEN 
                INSERT INTO nota (inscricao_id, avaliacao_id, nota, status) 
                VALUES (v_insc_atual, v_pai_atual, v_nota_pai, '1'); 
            END IF;
            
            -- Verificar recursividade (se este pai tem outro pai)
            BEGIN
                SELECT avaliacao_pai_id INTO v_pai_do_pai FROM avaliacao WHERE id = v_pai_atual;
                IF v_pai_do_pai IS NOT NULL THEN 
                    PKG_BUFFER_NOTA.ADICIONAR_PAI(v_insc_atual, v_pai_do_pai); 
                END IF;
            EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
            END;
        END LOOP;
    END IF;

    -- 2. Processar Nota Final da Inscrição (Loop Simples)
    IF PKG_BUFFER_NOTA.v_ids_finais.COUNT > 0 THEN
        FOR j IN 1..PKG_BUFFER_NOTA.v_ids_finais.COUNT LOOP
            v_insc_atual := PKG_BUFFER_NOTA.v_ids_finais(j);
            
            SELECT SUM(n.nota * (NVL(a.peso, 100) / 100)) INTO v_nota_pai 
            FROM nota n JOIN avaliacao a ON n.avaliacao_id = a.id
            WHERE n.inscricao_id = v_insc_atual 
              AND a.avaliacao_pai_id IS NULL 
              AND n.status = '1';
            
            UPDATE inscricao SET nota_final = v_nota_pai, updated_at = SYSDATE WHERE id = v_insc_atual;
        END LOOP;
    END IF;
    
    PKG_BUFFER_NOTA.LIMPAR;
    PKG_BUFFER_NOTA.g_a_calcular := FALSE;
    
EXCEPTION WHEN OTHERS THEN
    PKG_BUFFER_NOTA.g_a_calcular := FALSE;
    PKG_BUFFER_NOTA.LIMPAR;
    PKG_GESTAO_DADOS.PRC_LOG_ERRO('Erro no calculo automatico de notas: ' || SQLERRM);
END;
/

-- -----------------------------------------------------------------------------
-- 5.7. MÉDIA GERAL E CONCLUSÃO DE CURSO
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_INSCRICAO_POST_PROCESS
    AFTER UPDATE OF nota_final ON inscricao
    FOR EACH ROW
DECLARE
    v_cur_id    NUMBER;
    v_media     NUMBER; 
    v_ects      NUMBER; 
    v_total_obr NUMBER; 
    v_aprov     NUMBER;
BEGIN
    -- Evitar processamento se a nota for nula
    IF :NEW.nota_final IS NULL THEN RETURN; END IF;

    SELECT curso_id INTO v_cur_id FROM matricula WHERE id = :NEW.matricula_id;

    SELECT SUM(i.nota_final * uc.ects), SUM(uc.ects) INTO v_media, v_ects 
    FROM inscricao i JOIN turma t ON i.turma_id = t.id 
    JOIN uc_curso uc ON (t.unidade_curricular_id = uc.unidade_curricular_id)
    WHERE i.matricula_id = :NEW.matricula_id AND i.nota_final IS NOT NULL 
      AND i.status = '1' AND uc.curso_id = v_cur_id;

    IF v_ects > 0 THEN 
        UPDATE matricula SET media_geral = (v_media / v_ects), updated_at = SYSDATE 
        WHERE id = :NEW.matricula_id; 
    END IF;

    SELECT COUNT(*) INTO v_total_obr FROM uc_curso u 
    WHERE u.curso_id = v_cur_id AND u.presenca_obrigatoria = '1';
    
    SELECT COUNT(*) INTO v_aprov FROM inscricao 
    WHERE matricula_id = :NEW.matricula_id 
      AND nota_final >= PKG_CONSTANTES.NOTA_APROVACAO 
      AND status = '1';

    IF v_aprov >= v_total_obr AND v_total_obr > 0 THEN 
        UPDATE matricula SET estado_matricula_id = PKG_CONSTANTES.EST_MATRICULA_CONCLUIDA 
        WHERE id = :NEW.matricula_id; 
    END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- -----------------------------------------------------------------------------
-- 5.8. AUTOMAÇÕES (PRESENÇAS E PROPINAS)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUTO_PRESENCA_AULA
    AFTER INSERT ON aula
    FOR EACH ROW
BEGIN 
    INSERT INTO presenca (inscricao_id, aula_id, presente, status)
    SELECT id, :NEW.id, '0', '1' FROM inscricao WHERE turma_id = :NEW.turma_id AND status = '1';
END;
/

CREATE OR REPLACE TRIGGER TRG_AUTO_PRESENCA_ALUNO
    AFTER INSERT ON inscricao
    FOR EACH ROW
DECLARE
    v_aula_id NUMBER;
BEGIN 
    -- Cursor implícito num loop para evitar declarações extra
    FOR r IN (SELECT id FROM aula WHERE turma_id = :NEW.turma_id AND status = '1') LOOP
        INSERT INTO presenca (inscricao_id, aula_id, presente, status) 
        VALUES (:NEW.id, r.id, '0', '1');
    END LOOP;
END;
/

-- -----------------------------------------------------------------------------
-- 5.8.1. VALIDAÇÃO DE OBRIGATORIEDADE DE ENTREGA E PRAZO
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_ENTREGA_REGRAS
    BEFORE INSERT ON entrega
    FOR EACH ROW
DECLARE
    v_requer CHAR(1);
    v_prazo  DATE;
BEGIN
    SELECT ta.requer_entrega, a.data_entrega INTO v_requer, v_prazo
    FROM avaliacao a
    JOIN tipo_avaliacao ta ON a.tipo_avaliacao_id = ta.id
    WHERE a.id = :NEW.avaliacao_id;
    
    IF v_requer = '0' THEN
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: Esta avaliação não aceita entregas de ficheiros.');
    END IF;

    IF :NEW.data_entrega > v_prazo THEN
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: Entrega efetuada fora do prazo limite.');
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.8.2. EVITAR PRESENÇA DUPLICADA
-- Nota: Removido trigger complexo para evitar erro de Tabela Mutante (ORA-04091).
-- A unicidade (Aluno + Aula) é garantida pela Chave Primária da tabela PRESENCA.
-- -----------------------------------------------------------------------------
-- (Trigger removido nesta versão simplificada)


CREATE OR REPLACE TRIGGER TRG_AUTO_GERAR_PROPINAS 
    AFTER INSERT ON matricula 
    FOR EACH ROW
DECLARE
    v_valor_total NUMBER;
BEGIN 
    BEGIN
        SELECT tc.valor_propinas INTO v_valor_total
        FROM curso c 
        JOIN tipo_curso tc ON c.tipo_curso_id = tc.id 
        WHERE c.id = :NEW.curso_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        v_valor_total := 0;
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: Curso sem valor de propina definido. Definido como 0.');
    END;

    PKG_TESOURARIA.PRC_GERAR_PLANO_PAGAMENTO(:NEW.id, v_valor_total, :NEW.numero_parcelas); 
END;
/

-- -----------------------------------------------------------------------------
-- 5.9. VALIDAÇÃO DE DOCUMENTOS
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_DOCS_ESTUDANTE
    BEFORE INSERT OR UPDATE ON estudante
    FOR EACH ROW
BEGIN
    IF NOT PKG_VALIDACAO.FUN_VAL_NIF(:NEW.nif) THEN 
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: NIF inválido para ' || :NEW.nome); 
    END IF;
    IF NOT PKG_VALIDACAO.FUN_VAL_CC(:NEW.cc) THEN 
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: CC inválido para ' || :NEW.nome); 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_VAL_DOCS_DOCENTE
    BEFORE INSERT OR UPDATE ON docente
    FOR EACH ROW
BEGIN 
    IF NOT PKG_VALIDACAO.FUN_VAL_NIF(:NEW.nif) THEN 
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: NIF inválido para ' || :NEW.nome); 
    END IF;
    IF NOT PKG_VALIDACAO.FUN_VAL_CC(:NEW.cc) THEN 
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: CC inválido para ' || :NEW.nome); 
    END IF;
END;
/
