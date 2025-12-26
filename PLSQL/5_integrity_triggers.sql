-- =============================================================================
-- 5. TRIGGERS DE INTEGRIDADE E REGRAS DE NEGÓCIO
-- Corrigido: Triggers de Nota usam g_a_calcular para evitar recursividade
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
FOR INSERT OR UPDATE ON avaliacao
COMPOUND TRIGGER
    TYPE t_aval_rec IS RECORD (id NUMBER, tipo_id NUMBER, pai_id NUMBER, max_alunos NUMBER, turma_id NUMBER, peso NUMBER);
    TYPE t_aval_tab IS TABLE OF t_aval_rec;
    v_novas t_aval_tab := t_aval_tab();

    BEFORE EACH ROW IS
    BEGIN
        v_novas.EXTEND;
        v_novas(v_novas.LAST).id := :NEW.id;
        v_novas(v_novas.LAST).tipo_id := :NEW.tipo_avaliacao_id;
        v_novas(v_novas.LAST).pai_id := :NEW.avaliacao_pai_id;
        v_novas(v_novas.LAST).max_alunos := :NEW.max_alunos;
        v_novas(v_novas.LAST).turma_id := :NEW.turma_id;
        v_novas(v_novas.LAST).peso := :NEW.peso;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
        v_permite_filhos CHAR(1);
        v_permite_grupo  CHAR(1);
        v_cont_filhos    NUMBER;
        v_soma_pesos     NUMBER;
    BEGIN
        FOR i IN 1..v_novas.COUNT LOOP
            -- 1. Regra permite_filhos: Se tem pai, o pai tem de permitir filhos
            IF v_novas(i).pai_id IS NOT NULL THEN
                SELECT ta.permite_filhos INTO v_permite_filhos
                FROM avaliacao a
                JOIN tipo_avaliacao ta ON a.tipo_avaliacao_id = ta.id
                WHERE a.id = v_novas(i).pai_id;
                
                IF v_permite_filhos = '0' THEN
                    PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: A avaliação pai (ID '||v_novas(i).pai_id||') não permite sub-avaliações.');
                END IF;
            END IF;

            -- 2. Regra permite_grupo: Se max_alunos > 1, o tipo tem de permitir grupo
            SELECT permite_grupo, permite_filhos INTO v_permite_grupo, v_permite_filhos
            FROM tipo_avaliacao
            WHERE id = v_novas(i).tipo_id;
            
            IF v_novas(i).max_alunos > 1 AND v_permite_grupo = '0' THEN
                PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: O tipo de avaliação selecionado não permite trabalhos de grupo.');
            END IF;
            
            -- 3. Verificação de alteração: Se mudar para tipo que NÃO permite filhos, verificar se já os tem
            IF v_permite_filhos = '0' THEN
                SELECT COUNT(*) INTO v_cont_filhos FROM avaliacao WHERE avaliacao_pai_id = v_novas(i).id;
                IF v_cont_filhos > 0 THEN
                    PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: Alteração para tipo que não permite filhos com sub-avaliações existentes.');
                END IF;
            END IF;

            -- 4. Validação de pesos (não exceder 100% por turma para avaliações de topo)
            IF v_novas(i).pai_id IS NULL THEN
                SELECT SUM(peso) INTO v_soma_pesos FROM avaliacao 
                WHERE turma_id = v_novas(i).turma_id AND avaliacao_pai_id IS NULL AND status = '1';
                
                IF v_soma_pesos > 100 THEN
                    PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: O somatório dos pesos das avaliações da turma excede 100%.');
                END IF;
            ELSIF v_novas(i).pai_id IS NOT NULL THEN
                -- Validação de pesos dentro de uma avaliação pai
                SELECT SUM(peso) INTO v_soma_pesos FROM avaliacao 
                WHERE avaliacao_pai_id = v_novas(i).pai_id AND status = '1';
                
                IF v_soma_pesos > 100 THEN
                    PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: O somatório dos pesos das sub-avaliações excede 100% da avaliação pai.');
                END IF;
            END IF;
        END LOOP;
    END AFTER STATEMENT;
END;
/

-- -----------------------------------------------------------------------------
-- 5.2. CONFLITO DE HORÁRIO (SALA OU DOCENTE)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_HORARIO_AULA
FOR INSERT OR UPDATE ON aula
COMPOUND TRIGGER
    TYPE t_aula_rec IS RECORD (id NUMBER, data DATE, hora_inicio DATE, hora_fim DATE, sala_id NUMBER, turma_id NUMBER);
    TYPE t_aula_tab IS TABLE OF t_aula_rec;
    v_novas t_aula_tab := t_aula_tab();

    BEFORE EACH ROW IS
    BEGIN
        v_novas.EXTEND;
        v_novas(v_novas.LAST).id := :NEW.id;
        v_novas(v_novas.LAST).data := :NEW.data;
        v_novas(v_novas.LAST).hora_inicio := :NEW.hora_inicio;
        v_novas(v_novas.LAST).hora_fim := :NEW.hora_fim;
        v_novas(v_novas.LAST).sala_id := :NEW.sala_id;
        v_novas(v_novas.LAST).turma_id := :NEW.turma_id;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
        v_conflito NUMBER;
        v_doc_id   NUMBER;
    BEGIN
        FOR i IN 1..v_novas.COUNT LOOP
            SELECT docente_id INTO v_doc_id FROM turma WHERE id = v_novas(i).turma_id;
            
            SELECT COUNT(*) INTO v_conflito 
            FROM aula a JOIN turma t ON a.turma_id = t.id
            WHERE a.id != NVL(v_novas(i).id, -1)
              AND a.data = v_novas(i).data 
              AND a.status = '1'
              AND ((a.sala_id = v_novas(i).sala_id) OR (t.docente_id = v_doc_id))
              AND (v_novas(i).hora_inicio < a.hora_fim AND v_novas(i).hora_fim > a.hora_inicio);
              
            IF v_conflito > 0 THEN 
                PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: Conflito de horário detectado para sala ou docente na aula ' || v_novas(i).id);
            END IF;
        END LOOP;
    END AFTER STATEMENT;
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
    SELECT t.max_alunos INTO v_max FROM turma t WHERE t.id = :NEW.turma_id;
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
    DECLARE
        v_total_ects NUMBER;
    BEGIN
        SELECT SUM(uc.ects) INTO v_total_ects
        FROM inscricao i
        JOIN turma t ON i.turma_id = t.id
        JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
        WHERE i.matricula_id = :NEW.matricula_id 
          AND i.status = '1'
          AND uc.curso_id = v_cur_id;
          
        -- Adicionar ECTS da UC atual
        SELECT ects INTO v_existe FROM uc_curso WHERE curso_id = v_cur_id AND unidade_curricular_id = v_uc_id;
        v_total_ects := NVL(v_total_ects, 0) + v_existe;

        IF v_total_ects > PKG_CONSTANTES.LIMITE_ECTS_ANUAL(v_cur_id) THEN
            PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: Limite de ECTS anual excedido ('||v_total_ects||' > '||PKG_CONSTANTES.LIMITE_ECTS_ANUAL(v_cur_id)||')');
        END IF;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
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
    -- Se já estamos a calcular, não adicionamos nada ao buffer para evitar loops
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
    i              NUMBER; 
    j              NUMBER;
BEGIN
    -- Se já estamos a calcular, sai para não re-entrar
    IF PKG_BUFFER_NOTA.g_a_calcular THEN RETURN; END IF;

    -- Ativa flag para bloquear novos triggers durante os updates
    PKG_BUFFER_NOTA.g_a_calcular := TRUE;

    i := PKG_BUFFER_NOTA.v_lista.FIRST;
    LOOP
        EXIT WHEN i IS NULL;
        SELECT SUM(n.nota * (NVL(a.peso, 0) / 100)) INTO v_nota_pai 
        FROM nota n JOIN avaliacao a ON n.avaliacao_id = a.id
        WHERE n.inscricao_id = PKG_BUFFER_NOTA.v_lista(i).inscricao_id 
          AND a.avaliacao_pai_id = PKG_BUFFER_NOTA.v_lista(i).pai_id 
          AND n.status = '1';
          
        UPDATE nota SET nota = v_nota_pai, updated_at = SYSDATE 
        WHERE inscricao_id = PKG_BUFFER_NOTA.v_lista(i).inscricao_id 
          AND avaliacao_id = PKG_BUFFER_NOTA.v_lista(i).pai_id;
          
        IF SQL%ROWCOUNT = 0 THEN 
            INSERT INTO nota (inscricao_id, avaliacao_id, nota, status) 
            VALUES (PKG_BUFFER_NOTA.v_lista(i).inscricao_id, PKG_BUFFER_NOTA.v_lista(i).pai_id, v_nota_pai, '1'); 
        END IF;
        
        SELECT MAX(avaliacao_pai_id) INTO v_pai_do_pai FROM avaliacao WHERE id = PKG_BUFFER_NOTA.v_lista(i).pai_id;
        IF v_pai_do_pai IS NOT NULL THEN 
            PKG_BUFFER_NOTA.ADICIONAR_PAI(PKG_BUFFER_NOTA.v_lista(i).inscricao_id, v_pai_do_pai); 
        END IF;
        i := PKG_BUFFER_NOTA.v_lista.NEXT(i);
    END LOOP;

    j := PKG_BUFFER_NOTA.v_lista_insc.FIRST;
    LOOP
        EXIT WHEN j IS NULL;
        SELECT SUM(n.nota * (NVL(a.peso, 100) / 100)) INTO v_nota_pai 
        FROM nota n JOIN avaliacao a ON n.avaliacao_id = a.id
        WHERE n.inscricao_id = j AND a.avaliacao_pai_id IS NULL AND n.status = '1';
        
        UPDATE inscricao SET nota_final = v_nota_pai, updated_at = SYSDATE WHERE id = j;
        j := PKG_BUFFER_NOTA.v_lista_insc.NEXT(j);
    END LOOP;
    
    PKG_BUFFER_NOTA.LIMPAR;
    
    -- Desativa flag
    PKG_BUFFER_NOTA.g_a_calcular := FALSE;
    
EXCEPTION WHEN OTHERS THEN
    -- Garante que a flag é limpa mesmo em erro
    PKG_BUFFER_NOTA.g_a_calcular := FALSE;
    PKG_BUFFER_NOTA.LIMPAR;
    RAISE;
END;
/

-- -----------------------------------------------------------------------------
-- 5.7. MÉDIA GERAL E CONCLUSÃO DE CURSO
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_INSCRICAO_POST_PROCESS
FOR UPDATE OF nota_final ON inscricao
COMPOUND TRIGGER

    TYPE t_mat_tab IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    v_matriculas t_mat_tab;

    AFTER EACH ROW IS
    BEGIN
        v_matriculas(:NEW.matricula_id) := 1; 
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_mat_id    NUMBER;
        v_cur_id    NUMBER;
        v_media     NUMBER; 
        v_ects      NUMBER; 
        v_total_obr NUMBER; 
        v_aprov     NUMBER;
    BEGIN
        v_mat_id := v_matriculas.FIRST;
        WHILE v_mat_id IS NOT NULL LOOP
            
            SELECT curso_id INTO v_cur_id FROM matricula WHERE id = v_mat_id;

            SELECT SUM(i.nota_final * uc.ects), SUM(uc.ects) INTO v_media, v_ects 
            FROM inscricao i JOIN turma t ON i.turma_id = t.id 
            JOIN uc_curso uc ON (t.unidade_curricular_id = uc.unidade_curricular_id)
            WHERE i.matricula_id = v_mat_id AND i.nota_final IS NOT NULL 
              AND i.status = '1' AND uc.curso_id = v_cur_id;

            IF v_ects > 0 THEN 
                UPDATE matricula SET media_geral = (v_media / v_ects), updated_at = SYSDATE 
                WHERE id = v_mat_id; 
            END IF;

            SELECT COUNT(*) INTO v_total_obr FROM uc_curso u 
            WHERE u.curso_id = v_cur_id AND u.presenca_obrigatoria = '1';
            
            SELECT COUNT(*) INTO v_aprov FROM inscricao 
            WHERE matricula_id = v_mat_id 
              AND nota_final >= PKG_CONSTANTES.NOTA_APROVACAO 
              AND status = '1';

            IF v_aprov >= v_total_obr AND v_total_obr > 0 THEN 
                UPDATE matricula SET estado_matricula_id = PKG_CONSTANTES.EST_MATRICULA_CONCLUIDA 
                WHERE id = v_mat_id; 
            END IF;

            v_mat_id := v_matriculas.NEXT(v_mat_id);
        END LOOP;
    END AFTER STATEMENT;
END;
/

-- -----------------------------------------------------------------------------
-- 5.8. AUTOMAÇÕES (PRESENÇAS E PROPINAS)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUTO_PRESENCA_AULA
    AFTER INSERT ON aula
    FOR EACH ROW
DECLARE
    CURSOR c_inscritos IS SELECT id FROM inscricao WHERE turma_id = :NEW.turma_id AND status = '1';
    v_insc_id NUMBER;
BEGIN 
    OPEN c_inscritos;
    LOOP
        FETCH c_inscritos INTO v_insc_id; EXIT WHEN c_inscritos%NOTFOUND;
        INSERT INTO presenca (inscricao_id, aula_id, presente, status) 
        VALUES (v_insc_id, :NEW.id, '0', '1');
    END LOOP;
    CLOSE c_inscritos;
END;
/

CREATE OR REPLACE TRIGGER TRG_AUTO_PRESENCA_ALUNO
    AFTER INSERT ON inscricao
    FOR EACH ROW
DECLARE
    CURSOR c_aulas IS SELECT id FROM aula WHERE turma_id = :NEW.turma_id AND status = '1';
    v_aula_id NUMBER;
BEGIN 
    OPEN c_aulas;
    LOOP
        FETCH c_aulas INTO v_aula_id; EXIT WHEN c_aulas%NOTFOUND;
        INSERT INTO presenca (inscricao_id, aula_id, presente, status) 
        VALUES (:NEW.id, v_aula_id, '0', '1');
    END LOOP;
    CLOSE c_aulas;
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
-- 5.8.2. EVITAR PRESENÇA DUPLICADA (COMPOUND TRIGGER)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_PRESENCA_DUPLICADA
FOR INSERT OR UPDATE ON presenca
COMPOUND TRIGGER

    TYPE t_pres_rec IS RECORD (inscricao_id NUMBER, aula_id NUMBER);
    TYPE t_pres_tab IS TABLE OF t_pres_rec INDEX BY BINARY_INTEGER;
    v_presencas t_pres_tab;
    v_idx NUMBER := 0;

    BEFORE EACH ROW IS
    BEGIN
        IF :NEW.presente = '1' THEN
            v_idx := v_idx + 1;
            v_presencas(v_idx).inscricao_id := :NEW.inscricao_id;
            v_presencas(v_idx).aula_id := :NEW.aula_id;
        END IF;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
        v_conflito NUMBER;
        v_h_ini    DATE;
        v_h_fim    DATE;
        v_data     DATE;
        v_mat_id   NUMBER;
    BEGIN
        FOR i IN 1..v_presencas.COUNT LOOP
            -- 1. Obter dados da aula atual
            SELECT data, hora_inicio, hora_fim INTO v_data, v_h_ini, v_h_fim 
            FROM aula WHERE id = v_presencas(i).aula_id;
            
            -- 2. Obter matricula do aluno
            SELECT matricula_id INTO v_mat_id 
            FROM inscricao WHERE id = v_presencas(i).inscricao_id;

            -- 3. Verificar conflito com outras aulas onde o aluno esteve presente
            SELECT COUNT(*) INTO v_conflito
            FROM presenca p
            JOIN aula a ON p.aula_id = a.id
            JOIN inscricao i_join ON p.inscricao_id = i_join.id
            WHERE i_join.matricula_id = v_mat_id
              AND p.aula_id != v_presencas(i).aula_id
              AND p.presente = '1'
              AND a.data = v_data
              AND (v_h_ini < a.hora_fim AND v_h_fim > a.hora_inicio);

            IF v_conflito > 0 THEN
                PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: O estudante já tem presença marcada noutra aula no mesmo horário.');
            END IF;
        END LOOP;
    END AFTER STATEMENT;
END;
/

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