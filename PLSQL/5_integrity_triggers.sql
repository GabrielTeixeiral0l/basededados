-- =============================================================================
-- 5. TRIGGERS DE INTEGRIDADE E REGRA DE NEGÓCIO (COMPATÍVEL COM DDL V3)
-- =============================================================================

-- 5.1. VALIDAÇÃO DE NOTAS (0 a 20)
CREATE OR REPLACE TRIGGER TRG_VAL_NOTA
BEFORE INSERT OR UPDATE ON NOTA
FOR EACH ROW
BEGIN
    IF :NEW.nota < 0 OR :NEW.nota > 20 THEN
        PKG_LOG.ALERTA('Tentativa de inserir nota invalida: ' || :NEW.nota || ' para inscricao ' || :NEW.inscricao_id, 'NOTA');
    END IF;
END;
/

-- 5.1.1. CÁLCULO DE MÉDIAS - TRIGGER 1: INICIALIZAÇÃO (BEFORE STATEMENT)
CREATE OR REPLACE TRIGGER TRG_NOTA_MEDIA_BS
BEFORE INSERT OR UPDATE ON NOTA
BEGIN
    PKG_BUFFER_NOTA.LIMPAR;
END;
/

-- 5.1.1. CÁLCULO DE MÉDIAS - TRIGGER 2: CAPTURA (AFTER EACH ROW)
CREATE OR REPLACE TRIGGER TRG_NOTA_MEDIA_AR
AFTER INSERT OR UPDATE ON NOTA
FOR EACH ROW
DECLARE
    v_pai_id NUMBER;
BEGIN
    IF NOT PKG_BUFFER_NOTA.g_a_calcular THEN
        -- Verificar se a avaliação tem um pai
        SELECT avaliacao_pai_id INTO v_pai_id
        FROM avaliacao
        WHERE id = :NEW.avaliacao_id;

        IF v_pai_id IS NOT NULL THEN
            PKG_BUFFER_NOTA.ADICIONAR_PAI(:NEW.inscricao_id, v_pai_id);
        END IF;
    END IF;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN NULL;
    WHEN OTHERS THEN NULL;
END;
/

-- 5.1.1. CÁLCULO DE MÉDIAS - TRIGGER 3: PROCESSAMENTO (AFTER STATEMENT)
CREATE OR REPLACE TRIGGER TRG_NOTA_MEDIA_AS
AFTER INSERT OR UPDATE ON NOTA
DECLARE
    v_nota_final NUMBER;
    v_idx NUMBER;
    v_ins_id NUMBER;
    v_pai_id NUMBER;
    CURSOR c_calculo(p_ins_id NUMBER, p_pai_id NUMBER) IS
        SELECT NVL(SUM(n.nota * a.peso), 0)
        FROM nota n
        JOIN avaliacao a ON n.avaliacao_id = a.id
        WHERE a.avaliacao_pai_id = p_pai_id
          AND n.inscricao_id = p_ins_id;
BEGIN
    IF PKG_BUFFER_NOTA.v_ids_inscricao.COUNT > 0 THEN
        PKG_BUFFER_NOTA.g_a_calcular := TRUE;
        
        v_idx := PKG_BUFFER_NOTA.v_ids_inscricao.FIRST;
        LOOP
            EXIT WHEN v_idx IS NULL;
            
            v_ins_id := PKG_BUFFER_NOTA.v_ids_inscricao(v_idx);
            v_pai_id := PKG_BUFFER_NOTA.v_ids_pais(v_idx);

            -- Abrir cursor para calcular média
            OPEN c_calculo(v_ins_id, v_pai_id);
            FETCH c_calculo INTO v_nota_final;
            CLOSE c_calculo;

            -- Atualizar a nota do pai
            UPDATE nota 
            SET nota = v_nota_final, updated_at = CURRENT_TIMESTAMP
            WHERE inscricao_id = v_ins_id AND avaliacao_id = v_pai_id;

            -- Se não atualizou, insere
            IF SQL%ROWCOUNT = 0 THEN
                INSERT INTO nota (inscricao_id, avaliacao_id, nota)
                VALUES (v_ins_id, v_pai_id, v_nota_final);
            END IF;

            v_idx := PKG_BUFFER_NOTA.v_ids_inscricao.NEXT(v_idx);
        END LOOP;

        PKG_BUFFER_NOTA.LIMPAR;
        PKG_BUFFER_NOTA.g_a_calcular := FALSE;
    END IF;
EXCEPTION WHEN OTHERS THEN
    PKG_BUFFER_NOTA.g_a_calcular := FALSE;
    IF c_calculo%ISOPEN THEN CLOSE c_calculo; END IF;
    PKG_LOG.ERRO('Erro no processamento de medias (AS): '||SQLERRM, 'NOTA');
END;
/

-- 5.1.2. GERAÇÃO AUTOMÁTICA DE PRESENÇAS (AO INSCREVER ALUNO)
CREATE OR REPLACE TRIGGER TRG_AUTO_PRESENCA_INS
AFTER INSERT ON INSCRICAO
FOR EACH ROW
DECLARE
    CURSOR c_aulas IS 
        SELECT id FROM aula WHERE turma_id = :NEW.turma_id;
    v_aula_id NUMBER;
BEGIN
    OPEN c_aulas;
    LOOP
        FETCH c_aulas INTO v_aula_id;
        EXIT WHEN c_aulas%NOTFOUND;
        
        INSERT INTO presenca (inscricao_id, aula_id, presente)
        VALUES (:NEW.id, v_aula_id, '0');
    END LOOP;
    CLOSE c_aulas;
EXCEPTION WHEN OTHERS THEN
    IF c_aulas%ISOPEN THEN CLOSE c_aulas; END IF;
    PKG_LOG.ERRO('Erro ao gerar presenças automáticas para inscrição ' || :NEW.id, 'PRESENCA');
END;
/

-- 5.1.3. GERAÇÃO AUTOMÁTICA DE PRESENÇAS (AO CRIAR NOVA AULA)
CREATE OR REPLACE TRIGGER TRG_AUTO_PRESENCA_AULA
AFTER INSERT ON AULA
FOR EACH ROW
DECLARE
    CURSOR c_inscritos IS 
        SELECT id FROM inscricao WHERE turma_id = :NEW.turma_id AND status = '1';
    v_ins_id NUMBER;
BEGIN
    OPEN c_inscritos;
    LOOP
        FETCH c_inscritos INTO v_ins_id;
        EXIT WHEN c_inscritos%NOTFOUND;
        
        INSERT INTO presenca (inscricao_id, aula_id, presente)
        VALUES (v_ins_id, :NEW.id, '0');
    END LOOP;
    CLOSE c_inscritos;
EXCEPTION WHEN OTHERS THEN
    IF c_inscritos%ISOPEN THEN CLOSE c_inscritos; END IF;
    PKG_LOG.ERRO('Erro ao gerar presenças automáticas para aula ' || :NEW.id, 'PRESENCA');
END;
/

-- 5.2. VALIDAÇÃO DE REGRAS DE AVALIAÇÃO (FORÇAR MAX_ALUNOS = 1)
CREATE OR REPLACE TRIGGER TRG_VAL_AVALIACAO_REGRAS
BEFORE INSERT OR UPDATE ON AVALIACAO
FOR EACH ROW
DECLARE
    v_permite_grupo CHAR(1);
BEGIN
    -- Busca a regra no tipo de avaliação
    SELECT permite_grupo INTO v_permite_grupo
    FROM tipo_avaliacao
    WHERE id = :NEW.tipo_avaliacao_id;

    -- Se não permite grupo, forçar obrigatoriamente max_alunos = 1
    IF v_permite_grupo = '0' THEN
        :NEW.max_alunos := 1;
    END IF;

    -- Validar se o pai permite sub-avaliacoes (lógica existente)
    IF :NEW.avaliacao_pai_id IS NOT NULL THEN
        DECLARE
            v_pai_permite_filhos CHAR(1);
        BEGIN
            SELECT t.permite_filhos INTO v_pai_permite_filhos
            FROM avaliacao a
            JOIN tipo_avaliacao t ON a.tipo_avaliacao_id = t.id
            WHERE a.id = :NEW.avaliacao_pai_id;

            IF v_pai_permite_filhos = '0' THEN
                 PKG_LOG.ALERTA('A avaliacao pai ' || :NEW.avaliacao_pai_id || ' nao permite sub-avaliacoes.', 'AVALIACAO');
            END IF;
        EXCEPTION WHEN NO_DATA_FOUND THEN NULL; 
        END;
    END IF;
END;
/

-- 5.2.1. VALIDAÇÃO DE LIMITE DE GRUPO NA ENTREGA
CREATE OR REPLACE TRIGGER TRG_VAL_LIMITE_GRUPO_ENTREGA
BEFORE INSERT ON ESTUDANTE_ENTREGA
FOR EACH ROW
DECLARE
    v_max_alunos NUMBER;
    v_atual      NUMBER;
BEGIN
    -- 1. Buscar o limite da avaliação
    SELECT a.max_alunos INTO v_max_alunos
    FROM entrega e
    JOIN avaliacao a ON e.avaliacao_id = a.id
    WHERE e.id = :NEW.entrega_id;

    -- 2. Contar alunos já inscritos nesta entrega específica
    SELECT COUNT(*) INTO v_atual
    FROM estudante_entrega
    WHERE entrega_id = :NEW.entrega_id;

    -- 3. Se exceder, gerar alerta no LOG
    IF v_atual + 1 > v_max_alunos THEN
        PKG_LOG.ALERTA('Aviso de Limite: O limite de ' || v_max_alunos || 
                       ' aluno(s) foi excedido para a entrega ID ' || :NEW.entrega_id, 'ESTUDANTE_ENTREGA');
    END IF;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN NULL;
    WHEN OTHERS THEN PKG_LOG.ERRO('Erro em TRG_VAL_LIMITE_GRUPO_ENTREGA: ' || SQLERRM, 'ESTUDANTE_ENTREGA');
END;
/



-- 5.2.1. VALIDAÇÃO DE ENTREGAS
CREATE OR REPLACE TRIGGER TRG_VAL_ENTREGA_REGRAS
BEFORE INSERT ON ENTREGA
FOR EACH ROW
DECLARE
    v_req_entrega CHAR(1);
BEGIN
    SELECT ta.requer_entrega INTO v_req_entrega
    FROM avaliacao a
    JOIN tipo_avaliacao ta ON a.tipo_avaliacao_id = ta.id
    WHERE a.id = :NEW.avaliacao_id;

    IF v_req_entrega = '0' THEN
        PKG_LOG.ALERTA('A avaliacao ' || :NEW.avaliacao_id || ' nao requer entrega de ficheiros.', 'ENTREGA');
    END IF;
END;
/

-- 5.2.2. VALIDAÇÃO DE DADOS (ESTUDANTE E DOCENTE)
CREATE OR REPLACE TRIGGER TRG_VAL_DADOS_ESTUDANTE
BEFORE INSERT OR UPDATE ON ESTUDANTE
FOR EACH ROW
BEGIN
    -- Validar NIF
    IF NOT PKG_VALIDACAO.FUN_VALIDAR_NIF(:NEW.nif) THEN
        PKG_LOG.REGISTAR('ALERTA', 'NIF inválido para estudante: ' || :NEW.nif, 'ESTUDANTE');
    END IF;

    -- Validar CC
    IF NOT PKG_VALIDACAO.FUN_VALIDAR_CC(:NEW.cc) THEN
        PKG_LOG.REGISTAR('ALERTA', 'CC inválido para estudante: ' || :NEW.cc, 'ESTUDANTE');
    END IF;

    -- Validar Email
    IF NOT PKG_VALIDACAO.FUN_VALIDAR_EMAIL(:NEW.email) THEN
        PKG_LOG.REGISTAR('ALERTA', 'Email inválido para estudante: ' || :NEW.email, 'ESTUDANTE');
    END IF;

    -- Validar IBAN
    IF :NEW.iban IS NOT NULL AND NOT PKG_VALIDACAO.FUN_VALIDAR_IBAN(:NEW.iban) THEN
        PKG_LOG.REGISTAR('ALERTA', 'IBAN inválido para estudante: ' || :NEW.iban, 'ESTUDANTE');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_VAL_DADOS_DOCENTE
BEFORE INSERT OR UPDATE ON DOCENTE
FOR EACH ROW
BEGIN
    -- Validar NIF
    IF NOT PKG_VALIDACAO.FUN_VALIDAR_NIF(:NEW.nif) THEN
        PKG_LOG.REGISTAR('ALERTA', 'NIF inválido para docente: ' || :NEW.nif, 'DOCENTE');
    END IF;

    -- Validar CC
    IF :NEW.cc IS NOT NULL AND NOT PKG_VALIDACAO.FUN_VALIDAR_CC(:NEW.cc) THEN
        PKG_LOG.REGISTAR('ALERTA', 'CC inválido para docente: ' || :NEW.cc, 'DOCENTE');
    END IF;

    -- Validar Email
    IF :NEW.email IS NOT NULL AND NOT PKG_VALIDACAO.FUN_VALIDAR_EMAIL(:NEW.email) THEN
        PKG_LOG.REGISTAR('ALERTA', 'Email inválido para docente: ' || :NEW.email, 'DOCENTE');
    END IF;

    -- Validar IBAN
    IF :NEW.iban IS NOT NULL AND NOT PKG_VALIDACAO.FUN_VALIDAR_IBAN(:NEW.iban) THEN
        PKG_LOG.REGISTAR('ALERTA', 'IBAN inválido para docente: ' || :NEW.iban, 'DOCENTE');
    END IF;
END;
/

-- 5.3. VALIDAÇÃO DE SOBREPOSIÇÃO DE HORÁRIO (SALA E DOCENTE)
CREATE OR REPLACE TRIGGER TRG_VAL_HORARIO_AULA
BEFORE INSERT OR UPDATE ON AULA
FOR EACH ROW
DECLARE
    v_conflito_sala NUMBER;
    v_conflito_docente NUMBER;
    v_docente_id NUMBER;
BEGIN
    -- 1. Conflito de Sala
    SELECT COUNT(*) INTO v_conflito_sala
    FROM aula a
    WHERE a.sala_id = :NEW.sala_id
      AND a.data = :NEW.data
      AND a.id != NVL(:NEW.id, -1)
      AND (
          (:NEW.hora_inicio < a.hora_fim AND :NEW.hora_fim > a.hora_inicio)
      );

    IF v_conflito_sala > 0 THEN
        PKG_LOG.ALERTA('Conflito de horario na sala ' || :NEW.sala_id || ' em ' || TO_CHAR(:NEW.data, 'DD/MM/YYYY'), 'AULA');
    END IF;

    -- 2. Conflito de Docente
    SELECT docente_id INTO v_docente_id FROM turma WHERE id = :NEW.turma_id;

    SELECT COUNT(*) INTO v_conflito_docente
    FROM aula a
    JOIN turma t ON a.turma_id = t.id
    WHERE t.docente_id = v_docente_id
      AND a.data = :NEW.data
      AND a.id != NVL(:NEW.id, -1)
      AND (
          (:NEW.hora_inicio < a.hora_fim AND :NEW.hora_fim > a.hora_inicio)
      );

    IF v_conflito_docente > 0 THEN
        PKG_LOG.ALERTA('Conflito de horario para o docente ' || v_docente_id || ' em ' || TO_CHAR(:NEW.data, 'DD/MM/YYYY'), 'AULA');
    END IF;

EXCEPTION WHEN OTHERS THEN 
    PKG_LOG.ERRO('Erro no trigger TRG_VAL_HORARIO_AULA: ' || SQLERRM, 'AULA');
END;
/

-- 5.4. VALIDAÇÃO DE REGRAS DE ESTUDANTE (ECTS Anual)
CREATE OR REPLACE TRIGGER TRG_VAL_ESTUDANTE_REGRAS
BEFORE INSERT ON INSCRICAO
FOR EACH ROW
DECLARE
    v_total_ects NUMBER;
    v_novos_ects NUMBER;
    v_ano_letivo VARCHAR2(10);
    v_curso_id   NUMBER;
BEGIN
    SELECT m.curso_id, t.ano_letivo, uc.ects
    INTO v_curso_id, v_ano_letivo, v_novos_ects
    FROM matricula m
    JOIN turma t ON t.id = :NEW.turma_id
    JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
    WHERE m.id = :NEW.matricula_id
      AND uc.curso_id = m.curso_id;

    SELECT NVL(SUM(uc.ects), 0)
    INTO v_total_ects
    FROM inscricao i
    JOIN turma t ON i.turma_id = t.id
    JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
    WHERE i.matricula_id = :NEW.matricula_id
      AND t.ano_letivo = v_ano_letivo
      AND uc.curso_id = v_curso_id
      AND i.status = '1';

    IF (v_total_ects + v_novos_ects) > PKG_CONSTANTES.LIMITE_ECTS_ANUAL THEN
        PKG_LOG.ALERTA('Limite de ' || PKG_CONSTANTES.LIMITE_ECTS_ANUAL || ' ECTS anuais excedido para matricula ' || :NEW.matricula_id, 'INSCRICAO');
    END IF;
EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
END;
/

-- 5.5. GERAÇÃO AUTOMÁTICA DE PARCELAS DE PROPINA
CREATE OR REPLACE TRIGGER TRG_AUTO_GERAR_PROPINAS
AFTER INSERT ON MATRICULA
FOR EACH ROW
DECLARE
    v_valor_total NUMBER;
BEGIN
    SELECT tc.valor_propinas INTO v_valor_total
    FROM curso c
    JOIN tipo_curso tc ON c.tipo_curso_id = tc.id
    WHERE c.id = :NEW.curso_id;

    PKG_TESOURARIA.PRC_GERAR_PLANO_PAGAMENTO(:NEW.id, v_valor_total, :NEW.numero_parcelas);
EXCEPTION WHEN OTHERS THEN
    PKG_LOG.ERRO('Erro ao gerar propinas para matricula ' || :NEW.id || ': ' || SQLERRM, 'PARCELA_PROPINA');
END;
/

-- 5.6. PROTEÇÃO DA TABELA DE LOGS (IMUTABILIDADE COM RASTO)
CREATE OR REPLACE TRIGGER TRG_PROTEGER_LOG
BEFORE DELETE OR UPDATE ON LOG
FOR EACH ROW
DECLARE
    E_IMUTAVEL EXCEPTION;
    v_operacao VARCHAR2(20);
BEGIN
    IF NOT PKG_LOG.v_modo_manutencao THEN
        v_operacao := CASE WHEN DELETING THEN 'DELETE' ELSE 'UPDATE' END;
        
        -- Registar a tentativa de violação (Autonomous Transaction garante o rasto)
        PKG_LOG.REGISTAR('VIOLACAO_SEGURANCA', 
                         'Tentativa de ' || v_operacao || ' no log id: ' || :OLD.id, 
                         'LOG');
        
        RAISE E_IMUTAVEL;
    END IF;
END;
/