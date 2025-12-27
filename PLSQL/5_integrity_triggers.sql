-- =============================================================================
-- 5. TRIGGERS DE INTEGRIDADE E REGRA DE NEGÓCIO (COMPATÍVEL COM DDL V3)
-- =============================================================================

-- 5.1. VALIDAÇÃO DE NOTAS (0 a 20)
CREATE OR REPLACE TRIGGER TRG_VAL_NOTA
BEFORE INSERT OR UPDATE ON NOTA
FOR EACH ROW
BEGIN
    IF :NEW.nota < 0 OR :NEW.nota > 20 THEN
        PKG_LOG.ALERTA('Tentativa de inserir nota invalida: ' || :NEW.nota || ' para inscricao ' || :NEW.inscricao_id);
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
    PKG_LOG.ERRO('Erro no processamento de medias (AS): '||SQLERRM);
END;
/

-- 5.1.2. GERAÇÃO AUTOMÁTICA DE PRESENÇAS
CREATE OR REPLACE TRIGGER TRG_AUTO_PRESENCA
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
    PKG_LOG.ERRO('Erro ao gerar presenças automáticas para inscrição ' || :NEW.id);
END;
/

-- 5.2. VALIDAÇÃO DE REGRAS DE AVALIAÇÃO
CREATE OR REPLACE TRIGGER TRG_VAL_AVALIACAO_REGRAS
BEFORE INSERT OR UPDATE ON AVALIACAO
FOR EACH ROW
DECLARE
    v_tipo_req_entrega CHAR(1);
    v_tipo_perm_filhos CHAR(1);
BEGIN
    SELECT requer_entrega, permite_filhos
    INTO v_tipo_req_entrega, v_tipo_perm_filhos
    FROM tipo_avaliacao
    WHERE id = :NEW.tipo_avaliacao_id;

    IF :NEW.avaliacao_pai_id IS NOT NULL THEN
        DECLARE
            v_pai_permite_filhos CHAR(1);
        BEGIN
            SELECT t.permite_filhos INTO v_pai_permite_filhos
            FROM avaliacao a
            JOIN tipo_avaliacao t ON a.tipo_avaliacao_id = t.id
            WHERE a.id = :NEW.avaliacao_pai_id;

            IF v_pai_permite_filhos = '0' THEN
                 PKG_LOG.ALERTA('A avaliacao pai ' || :NEW.avaliacao_pai_id || ' nao permite sub-avaliacoes.');
            END IF;
        EXCEPTION WHEN NO_DATA_FOUND THEN NULL; 
        END;
    END IF;
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
        PKG_LOG.ALERTA('A avaliacao ' || :NEW.avaliacao_id || ' nao requer entrega de ficheiros.');
    END IF;
END;
/

-- 5.2.2. VALIDAÇÃO DE NIF (ESTUDANTE E DOCENTE)
CREATE OR REPLACE TRIGGER TRG_VAL_NIF_ESTUDANTE
BEFORE INSERT OR UPDATE ON ESTUDANTE
FOR EACH ROW
BEGIN
    IF NOT PKG_VALIDACAO.FUN_VALIDAR_NIF(:NEW.nif) THEN
        PKG_LOG.REGISTAR('ALERTA', 'NIF inválido para estudante: ' || :NEW.nif, 'ESTUDANTE');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_VAL_NIF_DOCENTE
BEFORE INSERT OR UPDATE ON DOCENTE
FOR EACH ROW
BEGIN
    IF NOT PKG_VALIDACAO.FUN_VALIDAR_NIF(:NEW.nif) THEN
        PKG_LOG.REGISTAR('ALERTA', 'NIF inválido para docente: ' || :NEW.nif, 'DOCENTE');
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
        PKG_LOG.ALERTA('Conflito de horario na sala ' || :NEW.sala_id || ' em ' || TO_CHAR(:NEW.data, 'DD/MM/YYYY'));
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
        PKG_LOG.ALERTA('Conflito de horario para o docente ' || v_docente_id || ' em ' || TO_CHAR(:NEW.data, 'DD/MM/YYYY'));
    END IF;

EXCEPTION WHEN OTHERS THEN 
    PKG_LOG.ERRO('Erro no trigger TRG_VAL_HORARIO_AULA: ' || SQLERRM);
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

    IF (v_total_ects + v_novos_ects) > 60 THEN
        PKG_LOG.ALERTA('Limite de 60 ECTS anuais excedido para matricula ' || :NEW.matricula_id);
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
    PKG_LOG.ERRO('Erro ao gerar propinas para matricula ' || :NEW.id || ': ' || SQLERRM);
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