-- =============================================================================
-- 5. TRIGGERS DE INTEGRIDADE E REGRA DE NEGÓCIO (COMPATÍVEL COM DDL V3)
-- =============================================================================

-- 5.1. VALIDAÇÃO DE NOTAS (Status, Limites e Integridade de Turma)
CREATE OR REPLACE TRIGGER TRG_VAL_NOTA
BEFORE INSERT OR UPDATE ON NOTA
FOR EACH ROW
DECLARE
    v_turma_inscricao NUMBER;
    v_turma_avaliacao NUMBER;
    E_NOTA_INVALIDA EXCEPTION;
    E_TURMA_INCONSISTENTE EXCEPTION;
BEGIN
    -- 1. Validar Status
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'NOTA');

    -- 2. Validar Limites (0 a 20)
    IF :NEW.nota < 0 OR :NEW.nota > 20 THEN
        PKG_LOG.ERRO('Tentativa de inserir nota invalida: ' || :NEW.nota || ' para inscricao ' || :NEW.inscricao_id, 'NOTA');
        RAISE E_NOTA_INVALIDA;
    END IF;

    -- 3. Validar Consistência de Turma (A inscrição e a avaliação devem pertencer à mesma turma)
    BEGIN
        SELECT turma_id INTO v_turma_inscricao FROM inscricao WHERE id = :NEW.inscricao_id;
        SELECT turma_id INTO v_turma_avaliacao FROM avaliacao WHERE id = :NEW.avaliacao_id;

        IF v_turma_inscricao != v_turma_avaliacao THEN
            PKG_LOG.ERRO('Inconsistencia: A inscricao ' || :NEW.inscricao_id || ' (Turma ' || v_turma_inscricao || 
                         ') nao pertence a turma da avaliacao ' || :NEW.avaliacao_id || ' (Turma ' || v_turma_avaliacao || ').', 'NOTA');
            RAISE E_TURMA_INCONSISTENTE;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Se não encontrar registos (ex: dados órfãos), deixamos as FKs tratarem do erro depois.
            NULL;
    END;

EXCEPTION
    WHEN E_NOTA_INVALIDA THEN RAISE;
    WHEN E_TURMA_INCONSISTENTE THEN RAISE;
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro desconhecido na validacao de nota: ' || SQLERRM, 'NOTA');
        RAISE;
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
        
        INSERT INTO presenca (inscricao_id, aula_id, presente, status)
        VALUES (:NEW.id, v_aula_id, '0', '1');
    END LOOP;
    CLOSE c_aulas;
EXCEPTION WHEN OTHERS THEN
    IF c_aulas%ISOPEN THEN CLOSE c_aulas; END IF;
    PKG_LOG.ERRO('Erro ao gerar presenças automáticas para inscrição ' || :NEW.id || ': ' || SQLERRM, 'PRESENCA');
    RAISE;
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
        
        INSERT INTO presenca (inscricao_id, aula_id, presente, status)
        VALUES (v_ins_id, :NEW.id, '0', '1');
    END LOOP;
    CLOSE c_inscritos;
EXCEPTION WHEN OTHERS THEN
    IF c_inscritos%ISOPEN THEN CLOSE c_inscritos; END IF;
    PKG_LOG.ERRO('Erro ao gerar presenças automáticas para aula ' || :NEW.id || ': ' || SQLERRM, 'PRESENCA');
    RAISE;
END;
/

-- 5.2. VALIDAÇÃO DE REGRAS DE AVALIAÇÃO
CREATE OR REPLACE TRIGGER TRG_VAL_AVALIACAO_REGRAS
BEFORE INSERT OR UPDATE ON AVALIACAO
FOR EACH ROW
DECLARE
    v_permite_grupo CHAR(1);
    v_requer_entrega CHAR(1);
    v_pai_permite_filhos CHAR(1);
    E_PAI_INVALIDO EXCEPTION;
BEGIN
    -- 1. Validar Status
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'AVALIACAO');

    -- 2. Validar Peso (0 a 1)
    IF :NEW.peso < 0 OR :NEW.peso > 1 THEN
        PKG_LOG.ERRO('Peso invalido (' || :NEW.peso || ') na avaliacao. Ajustado para 0.', 'AVALIACAO');
        :NEW.peso := 0;
    END IF;

    -- 3. Obter regras do Tipo de Avaliação
    BEGIN
        SELECT permite_grupo, requer_entrega 
        INTO v_permite_grupo, v_requer_entrega
        FROM tipo_avaliacao
        WHERE id = :NEW.tipo_avaliacao_id;

        -- 3.1. Regra de Grupo (Se não permite, força 1 aluno)
        IF v_permite_grupo = '0' THEN
            :NEW.max_alunos := 1;
        END IF;

        -- 3.2. Regra de Entrega e Datas
        IF v_requer_entrega = '0' THEN
            :NEW.data_entrega := NULL;
        ELSE
            IF :NEW.data_entrega IS NOT NULL AND :NEW.data_entrega < :NEW.data THEN
                PKG_LOG.ALERTA('Data de entrega anterior a data da avaliacao. Ajustada para a data inicial.', 'AVALIACAO');
                :NEW.data_entrega := :NEW.data;
            END IF;
        END IF;

    EXCEPTION WHEN NO_DATA_FOUND THEN
        PKG_LOG.ERRO('Tipo de Avaliacao ' || :NEW.tipo_avaliacao_id || ' nao encontrado.', 'AVALIACAO');
    END;

    -- 4. Validar Hierarquia (Pai)
    IF :NEW.avaliacao_pai_id IS NOT NULL THEN
        BEGIN
            SELECT t.permite_filhos INTO v_pai_permite_filhos
            FROM avaliacao a
            JOIN tipo_avaliacao t ON a.tipo_avaliacao_id = t.id
            WHERE a.id = :NEW.avaliacao_pai_id;

            IF v_pai_permite_filhos = '0' THEN
                 RAISE E_PAI_INVALIDO;
            END IF;
        EXCEPTION 
            WHEN NO_DATA_FOUND THEN NULL;
            WHEN E_PAI_INVALIDO THEN
                 PKG_LOG.ERRO('A avaliacao pai ' || :NEW.avaliacao_pai_id || ' nao permite sub-avaliacoes.', 'AVALIACAO');
                 RAISE;
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
    E_LIMITE_EXCEDIDO EXCEPTION;
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

    -- 3. Se exceder, abortar transação
    IF v_atual + 1 > v_max_alunos THEN
        RAISE E_LIMITE_EXCEDIDO;
    END IF;

EXCEPTION 
    WHEN NO_DATA_FOUND THEN 
        NULL;
    WHEN E_LIMITE_EXCEDIDO THEN
        PKG_LOG.ERRO('Erro: O limite de ' || v_max_alunos || ' aluno(s) foi excedido para a entrega ID ' || :NEW.entrega_id, 'ESTUDANTE_ENTREGA');
        RAISE;
    WHEN OTHERS THEN 
        PKG_LOG.ERRO('Erro em TRG_VAL_LIMITE_GRUPO_ENTREGA: ' || SQLERRM, 'ESTUDANTE_ENTREGA');
        RAISE;
END;
/

-- 5.2.2. VALIDAÇÃO DE REGRAS DE ASSOCIAÇÃO (ESTUDANTE_ENTREGA)
CREATE OR REPLACE TRIGGER TRG_VAL_EST_ENTREGA_REGRAS
BEFORE INSERT OR UPDATE ON ESTUDANTE_ENTREGA
FOR EACH ROW
DECLARE
    v_turma_entrega NUMBER;
    v_turma_inscricao NUMBER;
    v_avaliacao_id NUMBER;
    v_existe_duplicado NUMBER;
    E_INCONSISTENCIA EXCEPTION;
    E_DUPLICADO EXCEPTION;
BEGIN
    -- 1. Validar Status
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'ESTUDANTE_ENTREGA');

    -- Obter dados da Entrega/Avaliação
    BEGIN
        SELECT a.turma_id, a.id
        INTO v_turma_entrega, v_avaliacao_id
        FROM entrega e
        JOIN avaliacao a ON e.avaliacao_id = a.id
        WHERE e.id = :NEW.entrega_id;

        -- 2. Validar Consistência: A inscrição pertence à turma da avaliação?
        SELECT turma_id INTO v_turma_inscricao
        FROM inscricao
        WHERE id = :NEW.inscricao_id;

        IF v_turma_entrega != v_turma_inscricao THEN
             RAISE E_INCONSISTENCIA;
        END IF;

        -- 3. Validar Duplicação (A mesma inscrição já tem grupo nesta avaliação?)
        SELECT COUNT(*) INTO v_existe_duplicado
        FROM estudante_entrega ee
        JOIN entrega e ON ee.entrega_id = e.id
        WHERE e.avaliacao_id = v_avaliacao_id
          AND ee.inscricao_id = :NEW.inscricao_id
          AND ee.entrega_id != :NEW.entrega_id;

        IF v_existe_duplicado > 0 THEN
             RAISE E_DUPLICADO;
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
        WHEN E_INCONSISTENCIA THEN
            PKG_LOG.ERRO('Inconsistencia: Inscricao ' || :NEW.inscricao_id || ' pertence a turma ' || v_turma_inscricao || ' mas a entrega e da turma ' || v_turma_entrega, 'ESTUDANTE_ENTREGA');
            RAISE;
        WHEN E_DUPLICADO THEN
            PKG_LOG.ERRO('A inscricao ' || :NEW.inscricao_id || ' ja esta associada a um grupo nesta avaliacao.', 'ESTUDANTE_ENTREGA');
            RAISE;
    END;
END;
/

-- 5.2.3. VALIDAÇÃO DE ENTREGAS
CREATE OR REPLACE TRIGGER TRG_VAL_ENTREGA_REGRAS
BEFORE INSERT OR UPDATE ON ENTREGA
FOR EACH ROW
DECLARE
    v_req_entrega CHAR(1);
    v_data_inicio DATE;
    v_data_fim    DATE;
BEGIN
    -- 1. Validar Status
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'ENTREGA');

    -- 2. Obter dados da Avaliação
    BEGIN
        SELECT ta.requer_entrega, a.data, a.data_entrega
        INTO v_req_entrega, v_data_inicio, v_data_fim
        FROM avaliacao a
        JOIN tipo_avaliacao ta ON a.tipo_avaliacao_id = ta.id
        WHERE a.id = :NEW.avaliacao_id;

        -- 3. Validar se tipo requer entrega
        IF v_req_entrega = '0' THEN
            PKG_LOG.ALERTA('A avaliacao ' || :NEW.avaliacao_id || ' nao requer entrega de ficheiros.', 'ENTREGA');
        END IF;

        -- 4. Validar Prazos (Gera Alerta, não impede - permite entrega atrasada mas regista)
        IF :NEW.data_entrega < v_data_inicio THEN
             PKG_LOG.ALERTA('Entrega efetuada ANTES da data de inicio da avaliacao (' || TO_CHAR(v_data_inicio, 'YYYY-MM-DD') || ').', 'ENTREGA');
        ELSIF v_data_fim IS NOT NULL AND :NEW.data_entrega > v_data_fim THEN
             PKG_LOG.ALERTA('Entrega FORA DO PRAZO. Limite era: ' || TO_CHAR(v_data_fim, 'YYYY-MM-DD HH24:MI'), 'ENTREGA');
        END IF;

    EXCEPTION WHEN NO_DATA_FOUND THEN
        PKG_LOG.ERRO('Avaliacao ID ' || :NEW.avaliacao_id || ' nao encontrada ao validar entrega.', 'ENTREGA');
    END;
END;
/

-- 5.2.2. VALIDAÇÃO DE DADOS (ESTUDANTE E DOCENTE)
CREATE OR REPLACE TRIGGER TRG_VAL_DADOS_ESTUDANTE
BEFORE INSERT OR UPDATE ON ESTUDANTE
FOR EACH ROW
DECLARE
    E_DADOS_INVALIDOS EXCEPTION;
BEGIN
    -- 1. Validar Status
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'ESTUDANTE');

    -- 2. Validar Data de Nascimento (Idade Mínima Parametrizada)
    IF :NEW.data_nascimento IS NULL OR :NEW.data_nascimento > ADD_MONTHS(SYSDATE, -PKG_CONSTANTES.IDADE_MINIMA_ESTUDANTE*12) THEN
        PKG_LOG.ERRO('Data de nascimento invalida ou idade inferior a ' || PKG_CONSTANTES.IDADE_MINIMA_ESTUDANTE || ' anos para aluno: ' || :NEW.nome, 'ESTUDANTE');
        RAISE E_DADOS_INVALIDOS;
    END IF;

    -- 3. Validar Telemóvel
    IF :NEW.telemovel IS NOT NULL AND NOT PKG_VALIDACAO.FUN_VALIDAR_TELEMOVEL(:NEW.telemovel) THEN
        PKG_LOG.ERRO('Telemovel invalido: ' || :NEW.telemovel, 'ESTUDANTE');
        RAISE E_DADOS_INVALIDOS;
    END IF;

    -- 4. Validar Identidade (NIF, CC, Email, IBAN)
    IF NOT PKG_VALIDACAO.FUN_VALIDAR_NIF(:NEW.nif) THEN
        PKG_LOG.ERRO('NIF inválido para estudante: ' || :NEW.nif, 'ESTUDANTE');
        RAISE E_DADOS_INVALIDOS;
    END IF;

    IF :NEW.cc IS NOT NULL AND NOT PKG_VALIDACAO.FUN_VALIDAR_CC(:NEW.cc) THEN
        PKG_LOG.ERRO('CC inválido para estudante: ' || :NEW.cc, 'ESTUDANTE');
        RAISE E_DADOS_INVALIDOS;
    END IF;

    IF :NEW.email IS NOT NULL AND NOT PKG_VALIDACAO.FUN_VALIDAR_EMAIL(:NEW.email) THEN
        PKG_LOG.ERRO('Email inválido para estudante: ' || :NEW.email, 'ESTUDANTE');
        RAISE E_DADOS_INVALIDOS;
    END IF;

    IF :NEW.iban IS NOT NULL AND NOT PKG_VALIDACAO.FUN_VALIDAR_IBAN(:NEW.iban) THEN
        PKG_LOG.ERRO('IBAN inválido para estudante: ' || :NEW.iban, 'ESTUDANTE');
        RAISE E_DADOS_INVALIDOS;
    END IF;
EXCEPTION
    WHEN E_DADOS_INVALIDOS THEN RAISE;
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro inesperado na validacao de estudante: ' || SQLERRM, 'ESTUDANTE');
        RAISE;
END;
/

CREATE OR REPLACE TRIGGER TRG_VAL_DADOS_DOCENTE
BEFORE INSERT OR UPDATE ON DOCENTE
FOR EACH ROW
DECLARE
    E_DADOS_INVALIDOS EXCEPTION;
BEGIN
    -- 1. Validar Status
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'DOCENTE');

    -- 2. Validar Data de Contratação (Não pode ser futura)
    IF :NEW.data_contratacao > SYSDATE THEN
        PKG_LOG.ERRO('Data de contratacao no futuro: ' || TO_CHAR(:NEW.data_contratacao, 'DD/MM/YYYY'), 'DOCENTE');
        RAISE E_DADOS_INVALIDOS;
    END IF;

    -- 3. Validar Identidade e Contactos
    -- Telemovel (Obrigatorio no DDLv3)
    IF :NEW.telemovel IS NULL OR NOT PKG_VALIDACAO.FUN_VALIDAR_TELEMOVEL(:NEW.telemovel) THEN
        PKG_LOG.ERRO('Telemovel invalido ou ausente para docente: ' || NVL(:NEW.telemovel, 'NULL'), 'DOCENTE');
        RAISE E_DADOS_INVALIDOS;
    END IF;

    -- NIF
    IF NOT PKG_VALIDACAO.FUN_VALIDAR_NIF(:NEW.nif) THEN
        PKG_LOG.ERRO('NIF inválido para docente: ' || :NEW.nif, 'DOCENTE');
        RAISE E_DADOS_INVALIDOS;
    END IF;

    -- CC
    IF :NEW.cc IS NOT NULL AND NOT PKG_VALIDACAO.FUN_VALIDAR_CC(:NEW.cc) THEN
        PKG_LOG.ERRO('CC inválido para docente: ' || :NEW.cc, 'DOCENTE');
        RAISE E_DADOS_INVALIDOS;
    END IF;

    -- Email
    IF :NEW.email IS NOT NULL AND NOT PKG_VALIDACAO.FUN_VALIDAR_EMAIL(:NEW.email) THEN
        PKG_LOG.ERRO('Email inválido: ' || :NEW.email, 'DOCENTE');
        RAISE E_DADOS_INVALIDOS;
    END IF;

    -- IBAN
    IF :NEW.iban IS NOT NULL AND NOT PKG_VALIDACAO.FUN_VALIDAR_IBAN(:NEW.iban) THEN
        PKG_LOG.ERRO('IBAN inválido para docente: ' || :NEW.iban, 'DOCENTE');
        RAISE E_DADOS_INVALIDOS;
    END IF;
EXCEPTION
    WHEN E_DADOS_INVALIDOS THEN RAISE;
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro inesperado na validacao de docente: ' || SQLERRM, 'DOCENTE');
        RAISE;
END;
/

-- 5.3. VALIDAÇÃO DE HORÁRIOS DE AULA (Conflitos de Sala e Docente)
CREATE OR REPLACE TRIGGER TRG_VAL_HORARIO_AULA
BEFORE INSERT OR UPDATE ON AULA
FOR EACH ROW
DECLARE
    v_conflito_sala NUMBER;
    v_conflito_docente NUMBER;
    v_docente_id NUMBER;
    E_CONFLITO_SALA EXCEPTION;
    E_CONFLITO_DOCENTE EXCEPTION;
BEGIN
    -- 0. Validar Status
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'AULA');

    -- 0.1. Validar Sequência Temporal (Fim > Início)
    IF :NEW.hora_fim <= :NEW.hora_inicio THEN
        PKG_LOG.ALERTA('Hora de fim ('||TO_CHAR(:NEW.hora_fim, 'HH24:MI')||') anterior ou igual ao inicio na aula ID '||:NEW.id||'. Ajustado +1h.', 'AULA');
        :NEW.hora_fim := :NEW.hora_inicio + INTERVAL '1' HOUR;
    END IF;

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
        RAISE E_CONFLITO_SALA;
    END IF;

    -- 2. Conflito de Docente
    -- Nota: No DDLv3, o docente está associado à TURMA.
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
        RAISE E_CONFLITO_DOCENTE;
    END IF;

EXCEPTION
    WHEN E_CONFLITO_SALA THEN
        PKG_LOG.ERRO('Conflito de horario na sala ' || :NEW.sala_id || ' em ' || TO_CHAR(:NEW.data, 'DD/MM/YYYY'), 'AULA');
        RAISE;
    WHEN E_CONFLITO_DOCENTE THEN
        PKG_LOG.ERRO('Conflito de horario para o docente ' || v_docente_id || ' em ' || TO_CHAR(:NEW.data, 'DD/MM/YYYY'), 'AULA');
        RAISE;
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro no trigger TRG_VAL_HORARIO_AULA: ' || SQLERRM, 'AULA');
        RAISE;
END;
/

-- 5.4. VALIDAÇÃO DE INSCRIÇÃO (SISTEMA INTEGRADO - COMPOUND TRIGGER)
-- Resolve ORA-04091 ao consolidar ECTS, Duplicados e Horários
CREATE OR REPLACE TRIGGER TRG_VAL_INSCRICAO_INTEGRADO
FOR INSERT OR UPDATE ON INSCRICAO
COMPOUND TRIGGER

    TYPE r_insc IS RECORD (
        matricula_id NUMBER,
        turma_id     NUMBER,
        uc_id        NUMBER,
        ects         NUMBER,
        ano_letivo   VARCHAR2(10),
        curso_id     NUMBER
    );
    TYPE t_insc IS TABLE OF r_insc;
    v_list t_insc := t_insc();
    
    -- Exceções customizadas
    E_FORA_PLANO EXCEPTION;
    E_DUPLICADO EXCEPTION;
    E_LIMITE_ECTS EXCEPTION;

    BEFORE EACH ROW IS
        v_c_id NUMBER; v_u_id NUMBER; v_e NUMBER; v_ano VARCHAR2(10);
    BEGIN
        -- 1. Sanitizar Status
        PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'INSCRICAO');

        -- 2. Obter Dados de Contexto (Turma/Curso/ECTS)
        BEGIN
            SELECT t.unidade_curricular_id, m.curso_id, uc.ects, t.ano_letivo
            INTO v_u_id, v_c_id, v_e, v_ano
            FROM turma t
            JOIN matricula m ON m.id = :NEW.matricula_id
            JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
            WHERE t.id = :NEW.turma_id AND uc.curso_id = m.curso_id;

            -- 3. Guardar para validação em lote (After Statement)
            v_list.EXTEND;
            v_list(v_list.LAST).matricula_id := :NEW.matricula_id;
            v_list(v_list.LAST).turma_id     := :NEW.turma_id;
            v_list(v_list.LAST).uc_id        := v_u_id;
            v_list(v_list.LAST).ects         := v_e;
            v_list(v_list.LAST).ano_letivo   := v_ano;
            v_list(v_list.LAST).curso_id     := v_c_id;

        EXCEPTION 
            WHEN NO_DATA_FOUND THEN
                PKG_LOG.ERRO('UC fora do plano de estudos ou dados invalidos para a inscricao.', 'INSCRICAO');
                RAISE E_FORA_PLANO;
        END;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
        v_total_ects NUMBER;
        v_count NUMBER;
    BEGIN
        FOR i IN 1..v_list.COUNT LOOP
            -- 4. Validar Duplicados (MesMA UC)
            SELECT COUNT(*) INTO v_count FROM inscricao ins JOIN turma t ON ins.turma_id = t.id
            WHERE ins.matricula_id = v_list(i).matricula_id 
              AND t.unidade_curricular_id = v_list(i).uc_id AND ins.status = '1';
            
            IF v_count > 1 THEN 
                PKG_LOG.ERRO('Inscricao duplicada na mesma disciplina detetada.', 'INSCRICAO');
                RAISE E_DUPLICADO; 
            END IF;

            -- 5. Validar Limite de ECTS
            SELECT NVL(SUM(uc.ects), 0) INTO v_total_ects
            FROM inscricao ins
            JOIN turma t ON ins.turma_id = t.id
            JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
            WHERE ins.matricula_id = v_list(i).matricula_id 
              AND t.ano_letivo = v_list(i).ano_letivo
              AND uc.curso_id = v_list(i).curso_id AND ins.status = '1';

            IF v_total_ects > PKG_CONSTANTES.LIMITE_ECTS_ANUAL THEN
                PKG_LOG.ERRO('Limite de '||PKG_CONSTANTES.LIMITE_ECTS_ANUAL||' ECTS excedido para a matricula '||v_list(i).matricula_id||' (Total: '||v_total_ects||').', 'INSCRICAO');
                RAISE E_LIMITE_ECTS;
            END IF;
        END LOOP;
        v_list.DELETE;
    END AFTER STATEMENT;
END;
/

-- 5.11. ATUALIZAÇÃO AUTOMÁTICA DA MÉDIA GERAL (SISTEMA DE 3 TRIGGERS)

-- Trigger 1: Inicialização (Before Statement)
CREATE OR REPLACE TRIGGER TRG_MEDIA_MAT_BS
BEFORE UPDATE OF nota_final ON INSCRICAO
BEGIN
    PKG_BUFFER_MATRICULA.LIMPAR;
END;
/

-- Trigger 2: Captura (After Row)
CREATE OR REPLACE TRIGGER TRG_MEDIA_MAT_AR
AFTER UPDATE OF nota_final ON INSCRICAO
FOR EACH ROW
BEGIN
    -- Se a nota mudou, marca a matricula para recalculo
    IF :NEW.nota_final IS NOT NULL AND (:OLD.nota_final IS NULL OR :NEW.nota_final != :OLD.nota_final) THEN
        PKG_BUFFER_MATRICULA.ADICIONAR(:NEW.matricula_id);
    END IF;
END;
/

-- Trigger 3: Processamento (After Statement)
CREATE OR REPLACE TRIGGER TRG_MEDIA_MAT_AS
AFTER UPDATE OF nota_final ON INSCRICAO
DECLARE
    v_media_ponderada NUMBER;
    v_total_ects NUMBER;
    v_mat_id NUMBER;
    v_idx NUMBER;
BEGIN
    IF PKG_BUFFER_MATRICULA.v_ids_matricula.COUNT > 0 THEN
        v_idx := PKG_BUFFER_MATRICULA.v_ids_matricula.FIRST;
        
        LOOP
            EXIT WHEN v_idx IS NULL;
            v_mat_id := PKG_BUFFER_MATRICULA.v_ids_matricula(v_idx);

            -- Calcular média
            SELECT NVL(SUM(i.nota_final * uc.ects), 0), NVL(SUM(uc.ects), 0)
            INTO v_media_ponderada, v_total_ects
            FROM inscricao i
            JOIN turma t ON i.turma_id = t.id
            JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
            WHERE i.matricula_id = v_mat_id
              AND i.nota_final >= PKG_CONSTANTES.NOTA_APROVACAO
              AND i.status = '1';

            IF v_total_ects > 0 THEN
                UPDATE matricula 
                SET media_geral = ROUND(v_media_ponderada / v_total_ects, 2)
                WHERE id = v_mat_id;
            END IF;

            v_idx := PKG_BUFFER_MATRICULA.v_ids_matricula.NEXT(v_idx);
        END LOOP;
        
        PKG_BUFFER_MATRICULA.LIMPAR;
    END IF;
EXCEPTION WHEN OTHERS THEN
    PKG_LOG.ERRO('Erro no calculo de media (AS): ' || SQLERRM, 'MATRICULA');
END;
/

-- 5.12. VALIDAÇÃO DE MATRÍCULA (DUPLICIDADE, PARCELAS E STATUS)
CREATE OR REPLACE TRIGGER TRG_VAL_MATRICULA
BEFORE INSERT OR UPDATE ON MATRICULA
FOR EACH ROW
DECLARE
    E_DUPLICADO EXCEPTION;
    E_PARCELAS_INVALIDAS EXCEPTION;
    v_count NUMBER;
BEGIN
    -- 1. Validar Status
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'MATRICULA');

    -- 2. Validar Número de Parcelas (Min 1, Max 12)
    IF :NEW.numero_parcelas < PKG_CONSTANTES.MIN_PARCELAS OR :NEW.numero_parcelas > PKG_CONSTANTES.MAX_PARCELAS THEN
        PKG_LOG.ERRO('Numero de parcelas invalido ('||:NEW.numero_parcelas||'). Deve ser entre '||
                     PKG_CONSTANTES.MIN_PARCELAS||' e '||PKG_CONSTANTES.MAX_PARCELAS, 'MATRICULA');
        RAISE E_PARCELAS_INVALIDAS;
    END IF;

    -- 3. Impedir Duplicidade de Matrícula Ativa no mesmo Curso
    -- Otimização: Só validar se for INSERT ou se o estado/status mudar para ativo
    IF (:NEW.status = '1' AND :NEW.estado_matricula = 'Ativa') AND
       (INSERTING OR (:OLD.estado_matricula != 'Ativa') OR (:OLD.status != '1')) THEN
       
        SELECT COUNT(*) INTO v_count
        FROM matricula
        WHERE estudante_id = :NEW.estudante_id
          AND curso_id = :NEW.curso_id
          AND estado_matricula = 'Ativa'
          AND status = '1'
          AND id != NVL(:NEW.id, -1);

        IF v_count > 0 THEN
            PKG_LOG.ERRO('Aluno ja tem uma matricula ativa neste curso.', 'MATRICULA');
            RAISE E_DUPLICADO;
        END IF;
    END IF;

EXCEPTION
    WHEN E_PARCELAS_INVALIDAS THEN RAISE;
    WHEN E_DUPLICADO THEN RAISE;
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro na validacao de matricula: ' || SQLERRM, 'MATRICULA');
        RAISE;
END;
/

-- 5.5. GERAR PROPINAS AUTOMATICAMENTE AO MATRICULAR
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

-- 5.6. VALIDAÇÃO DE SALA (STATUS E CAPACIDADE)
CREATE OR REPLACE TRIGGER TRG_VAL_SALA
BEFORE INSERT OR UPDATE ON SALA
FOR EACH ROW
BEGIN
    -- 1. Validar Status (0 ou 1)
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'SALA');

    -- 2. Garantir Capacidade Positiva
    IF :NEW.capacidade <= 0 OR :NEW.capacidade IS NULL THEN
        PKG_LOG.ERRO('Capacidade invalida (' || NVL(TO_CHAR(:NEW.capacidade), 'NULL') || ') na sala ' || :NEW.nome || '. Forcada a 1.', 'SALA');
        :NEW.capacidade := 1;
    END IF;
END;
/

-- 5.7. VALIDAÇÃO DE CURSO (STATUS, DURACAO, ECTS)
CREATE OR REPLACE TRIGGER TRG_VAL_CURSO
BEFORE INSERT OR UPDATE ON CURSO
FOR EACH ROW
BEGIN
    -- 1. Validar Status
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'CURSO');

    -- 2. Validar Duração (Positiva)
    IF :NEW.duracao <= 0 OR :NEW.duracao IS NULL THEN
        PKG_LOG.ERRO('Duracao invalida (' || NVL(TO_CHAR(:NEW.duracao), 'NULL') || ') no curso ' || :NEW.nome || '. Ajustada para 1 ano.', 'CURSO');
        :NEW.duracao := 1;
    END IF;

    -- 3. Validar ECTS (Positivos)
    IF :NEW.ects < 0 OR :NEW.ects IS NULL THEN
        PKG_LOG.ERRO('ECTS invalidos (' || NVL(TO_CHAR(:NEW.ects), 'NULL') || ') no curso ' || :NEW.nome || '. Ajustado para 0.', 'CURSO');
        :NEW.ects := 0;
    END IF;
END;
/

-- 5.9. VALIDAÇÃO DE FICHEIRO DE ENTREGA (STATUS E TAMANHO)
CREATE OR REPLACE TRIGGER TRG_VAL_FICHEIRO_ENTREGA
BEFORE INSERT OR UPDATE ON FICHEIRO_ENTREGA
FOR EACH ROW
DECLARE
    E_TAMANHO_INVALIDO EXCEPTION;
BEGIN
    -- 1. Validar Status
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'FICHEIRO_ENTREGA');

    -- 2. Validar Tamanho
    IF NOT PKG_VALIDACAO.FUN_VALIDAR_TAMANHO_FICHEIRO(:NEW.tamanho) THEN
        PKG_LOG.ERRO('Tamanho de ficheiro invalido: ' || NVL(TO_CHAR(:NEW.tamanho), 'NULL') || 
                     ' (Max: ' || PKG_CONSTANTES.TAMANHO_MAX_FICHEIRO || ')', 'FICHEIRO_ENTREGA');
        RAISE E_TAMANHO_INVALIDO;
    END IF;
EXCEPTION
    WHEN E_TAMANHO_INVALIDO THEN RAISE;
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro na validacao de ficheiro: ' || SQLERRM, 'FICHEIRO_ENTREGA');
        RAISE;
END;
/

-- 5.10. VALIDAÇÃO DE FICHEIRO DE RECURSO (STATUS E TAMANHO)
CREATE OR REPLACE TRIGGER TRG_VAL_FICHEIRO_RECURSO
BEFORE INSERT OR UPDATE ON FICHEIRO_RECURSO
FOR EACH ROW
DECLARE
    E_TAMANHO_INVALIDO EXCEPTION;
BEGIN
    -- 1. Validar Status
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'FICHEIRO_RECURSO');

    -- 2. Validar Tamanho (obtendo o tamanho do BLOB)
    IF NOT PKG_VALIDACAO.FUN_VALIDAR_TAMANHO_FICHEIRO(DBMS_LOB.GETLENGTH(:NEW.ficheiro)) THEN
        PKG_LOG.ERRO('Tamanho de ficheiro de recurso invalido: ' || NVL(TO_CHAR(DBMS_LOB.GETLENGTH(:NEW.ficheiro)), 'NULL') || 
                     ' (Max: ' || PKG_CONSTANTES.TAMANHO_MAX_FICHEIRO || ')', 'FICHEIRO_RECURSO');
        RAISE E_TAMANHO_INVALIDO;
    END IF;
EXCEPTION
    WHEN E_TAMANHO_INVALIDO THEN RAISE;
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro na validacao de ficheiro de recurso: ' || SQLERRM, 'FICHEIRO_RECURSO');
        RAISE;
END;
/

-- 5.8. PROTEÇÃO DA TABELA DE LOGS (IMUTABILIDADE COM RASTO)
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


-- 5.13. VALIDAÇÃO DE PARCELA DE PROPINA
CREATE OR REPLACE TRIGGER TRG_VAL_PARCELA_PROPINA
BEFORE INSERT OR UPDATE ON PARCELA_PROPINA
FOR EACH ROW
DECLARE
    v_total_curso NUMBER;
    v_num_parcelas NUMBER;
    v_mat_id NUMBER;
    E_DADOS_INVALIDOS EXCEPTION;
BEGIN
    -- 1. Validar Status (Usando a função centralizada)
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.estado, 'PARCELA_PROPINA');

    -- 2. Validar Valor Positivo
    IF :NEW.valor <= 0 THEN
        PKG_LOG.ERRO('Valor da parcela deve ser maior que 0.', 'PARCELA_PROPINA');
        RAISE E_DADOS_INVALIDOS;
    END IF;

    -- 3. Validar Data de Vencimento (Futura no Registo)
    IF INSERTING THEN
        IF :NEW.data_vencimento <= TRUNC(SYSDATE) THEN
             PKG_LOG.ERRO('Data de vencimento deve ser futura (' || TO_CHAR(:NEW.data_vencimento, 'DD/MM/YYYY') || ').', 'PARCELA_PROPINA');
             RAISE E_DADOS_INVALIDOS;
        END IF;
    END IF;

    -- 4. Consistência de Pagamento
    IF :NEW.estado = '0' THEN
        :NEW.data_pagamento := NULL;
    ELSIF :NEW.estado = '1' AND :NEW.data_pagamento IS NULL THEN
        :NEW.data_pagamento := SYSDATE;
    END IF;

EXCEPTION
    WHEN E_DADOS_INVALIDOS THEN RAISE;
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro na validacao de parcela: ' || SQLERRM, 'PARCELA_PROPINA');
        RAISE;
END;
/

-- 5.14. VALIDAÇÃO DE PRESENÇA (Integridade Académica)
CREATE OR REPLACE TRIGGER TRG_VAL_PRESENCA
BEFORE INSERT OR UPDATE ON PRESENCA
FOR EACH ROW
DECLARE
    v_turma_aula    NUMBER;
    v_turma_insc    NUMBER;
    v_data_aula     DATE;
    E_DADOS_INVALIDOS EXCEPTION;
BEGIN
    -- 1. Validar Status
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'PRESENCA');

    -- 2. Validar valor do campo presente ('0' ou '1')
    IF :NEW.presente NOT IN ('0', '1') THEN
        :NEW.presente := '0'; -- Default para falta se o dado for lixo
    END IF;

    -- 3. Verificar se Aluno e Aula pertencem à mesma Turma
    -- NOTA: Como a tabela AULA e INSCRICAO não mudam durante este processo, não há erro de mutação aqui.
    SELECT data, turma_id INTO v_data_aula, v_turma_aula FROM aula WHERE id = :NEW.aula_id;
    SELECT turma_id INTO v_turma_insc FROM inscricao WHERE id = :NEW.inscricao_id;

    IF v_turma_aula != v_turma_insc THEN
        PKG_LOG.ERRO('Inconsistencia: Aluno da Inscrição '||:NEW.inscricao_id||' (Turma '||v_turma_insc||') tentou registar presenca na Aula '||:NEW.aula_id||' (Turma '||v_turma_aula||')', 'PRESENCA');
        RAISE E_DADOS_INVALIDOS;
    END IF;

    -- 4. Impedir marcar presença em aulas futuras (Só permite falta '0')
    IF :NEW.presente = '1' AND v_data_aula > TRUNC(SYSDATE) THEN
        PKG_LOG.ALERTA('Tentativa de marcar presenca em aula futura (Data: '||TO_CHAR(v_data_aula, 'DD/MM/YYYY')||') bloqueada.', 'PRESENCA');
        :NEW.presente := '0'; 
    END IF;

EXCEPTION
    WHEN E_DADOS_INVALIDOS THEN RAISE;
    WHEN NO_DATA_FOUND THEN
        PKG_LOG.ERRO('Aula ou Inscricao nao encontrada para validar presenca.', 'PRESENCA');
        RAISE;
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro na validacao de presenca: ' || SQLERRM, 'PRESENCA');
        RAISE;
END;
/


-- =============================================================================
-- 5.15. VALIDAÇÃO DE RECURSO
-- =============================================================================
CREATE OR REPLACE TRIGGER TRG_VAL_RECURSO
BEFORE INSERT OR UPDATE ON RECURSO
FOR EACH ROW
DECLARE
    v_turma_docente NUMBER;
    E_DOCENTE_NAO_TURMA EXCEPTION;
BEGIN
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'RECURSO');

    -- Verifica se o docente é o responsável pela turma
    SELECT docente_id INTO v_turma_docente FROM turma WHERE id = :NEW.turma_id;
    
    IF :NEW.docente_id != v_turma_docente THEN
        RAISE E_DOCENTE_NAO_TURMA;
    END IF;
EXCEPTION
    WHEN E_DOCENTE_NAO_TURMA THEN
        PKG_LOG.ERRO('Docente '||:NEW.docente_id||' nao pertence a turma '||:NEW.turma_id, 'RECURSO');
        RAISE;
END;
/

-- =============================================================================
-- 5.16. VALIDAÇÃO DE TIPO_AULA E TIPO_AVALIACAO
-- =============================================================================
CREATE OR REPLACE TRIGGER TRG_VAL_TIPO_AULA
BEFORE INSERT OR UPDATE ON TIPO_AULA
FOR EACH ROW
BEGIN
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'TIPO_AULA');
END;
/

CREATE OR REPLACE TRIGGER TRG_VAL_TIPO_AVALIACAO
BEFORE INSERT OR UPDATE ON TIPO_AVALIACAO
FOR EACH ROW
BEGIN
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'TIPO_AVALIACAO');
    
    IF :NEW.requer_entrega NOT IN ('0','1') THEN :NEW.requer_entrega := '0'; END IF;
    IF :NEW.permite_grupo NOT IN ('0','1') THEN :NEW.permite_grupo := '0'; END IF;
    IF :NEW.permite_filhos NOT IN ('0','1') THEN :NEW.permite_filhos := '0'; END IF;
END;
/

-- =============================================================================
-- 5.17. VALIDAÇÃO DE TIPO_CURSO E UNIDADE_CURRICULAR
-- =============================================================================
CREATE OR REPLACE TRIGGER TRG_VAL_TIPO_CURSO
BEFORE INSERT OR UPDATE ON TIPO_CURSO
FOR EACH ROW
BEGIN
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'TIPO_CURSO');
    IF :NEW.valor_propinas < 0 THEN
        PKG_LOG.ERRO('Valor de propinas negativo', 'TIPO_CURSO');
        :NEW.valor_propinas := 0;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_VAL_UC
BEFORE INSERT OR UPDATE ON UNIDADE_CURRICULAR
FOR EACH ROW
BEGIN
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'UNIDADE_CURRICULAR');
    IF :NEW.horas_teoricas < 0 THEN :NEW.horas_teoricas := 0; END IF;
    IF :NEW.horas_praticas < 0 THEN :NEW.horas_praticas := 0; END IF;
END;
/

-- =============================================================================
-- 5.18. VALIDAÇÃO DE TURMA
-- =============================================================================
CREATE OR REPLACE TRIGGER TRG_VAL_TURMA
BEFORE INSERT OR UPDATE ON TURMA
FOR EACH ROW
DECLARE
    v_exists NUMBER;
    E_DOCENTE_INVALIDO EXCEPTION;
BEGIN
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'TURMA');

    -- Verifica se o par (UC, Docente) existe na tabela de competências uc_docente
    SELECT COUNT(*) INTO v_exists 
    FROM uc_docente 
    WHERE unidade_curricular_id = :NEW.unidade_curricular_id 
      AND docente_id = :NEW.docente_id;

    IF v_exists = 0 THEN
        RAISE E_DOCENTE_INVALIDO;
    END IF;

    IF :NEW.max_alunos < 1 THEN :NEW.max_alunos := 1; END IF;
EXCEPTION
    WHEN E_DOCENTE_INVALIDO THEN
        PKG_LOG.ERRO('O docente '||:NEW.docente_id||' nao esta habilitado para a UC '||:NEW.unidade_curricular_id, 'TURMA');
        RAISE;
END;
/

-- =============================================================================
-- 5.19. VALIDAÇÃO DE UC_CURSO E UC_DOCENTE
-- =============================================================================
CREATE OR REPLACE TRIGGER TRG_VAL_UC_CURSO
BEFORE INSERT OR UPDATE ON UC_CURSO
FOR EACH ROW
DECLARE
    v_duracao_curso NUMBER;
    E_DURACAO_EXCEDIDA EXCEPTION;
    E_PRESENCA_INVALIDA EXCEPTION;
BEGIN
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'UC_CURSO');
    
    -- Validar duração
    SELECT duracao INTO v_duracao_curso FROM curso WHERE id = :NEW.curso_id;
    IF :NEW.ano > v_duracao_curso THEN
        RAISE E_DURACAO_EXCEDIDA;
    END IF;

    -- Validar regras de presença
    IF :NEW.presenca_obrigatoria NOT IN ('0','1') THEN :NEW.presenca_obrigatoria := '0'; END IF;

    IF :NEW.presenca_obrigatoria = '1' AND :NEW.percentagem_presenca IS NULL THEN
        :NEW.percentagem_presenca := PKG_CONSTANTES.PERCENTAGEM_PRESENCA_DEFAULT;
        PKG_LOG.ERRO('Percentagem de presenca nao definida. Aplicado default: ' || :NEW.percentagem_presenca, 'UC_CURSO');
    END IF;
    
    IF :NEW.presenca_obrigatoria = '0' THEN
        :NEW.percentagem_presenca := NULL;
    END IF;

EXCEPTION
    WHEN E_DURACAO_EXCEDIDA THEN
        PKG_LOG.ERRO('Ano '||:NEW.ano||' superior a duracao do curso ('||v_duracao_curso||')', 'UC_CURSO');
        RAISE;
    WHEN E_PRESENCA_INVALIDA THEN
        PKG_LOG.ERRO('Percentagem de presenca obrigatoria nao definida', 'UC_CURSO');
        RAISE;
END;
/

CREATE OR REPLACE TRIGGER TRG_VAL_UC_DOCENTE
BEFORE INSERT OR UPDATE ON UC_DOCENTE
FOR EACH ROW
BEGIN
    PKG_VALIDACAO.VALIDAR_STATUS(:NEW.status, 'UC_DOCENTE');
END;
/