-- =============================================================================
-- 5. TRIGGERS DE INTEGRIDADE E REGRA DE NEGÓCIO (COMPATÍVEL COM DDL V3)
-- =============================================================================

-- 5.1. VALIDAÇÃO DE NOTAS (0 a 20)
CREATE OR REPLACE TRIGGER TRG_VAL_NOTA
BEFORE INSERT OR UPDATE ON NOTA
FOR EACH ROW
DECLARE
    E_NOTA_INVALIDA EXCEPTION;
BEGIN
    IF :NEW.nota < 0 OR :NEW.nota > 20 THEN
        PKG_LOG.ERRO('Tentativa de inserir nota invalida: ' || :NEW.nota || ' para inscricao ' || :NEW.inscricao_id, 'NOTA');
        RAISE E_NOTA_INVALIDA;
    END IF;
EXCEPTION
    WHEN E_NOTA_INVALIDA THEN
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
        PKG_LOG.ERRO('IBAN inválido: ' || :NEW.iban, 'DOCENTE');
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
-- 5.4. VALIDAÇÃO DE REGRAS DE INSCRIÇÃO (ECTS Anual)
CREATE OR REPLACE TRIGGER TRG_VAL_INSCRICAO_ECTS
BEFORE INSERT ON INSCRICAO
FOR EACH ROW
DECLARE
    v_total_ects NUMBER;
    v_novos_ects NUMBER;
    v_ano_letivo VARCHAR2(10);
    v_curso_id   NUMBER;
    E_LIMITE_ECTS EXCEPTION;
BEGIN
    -- Obter dados da turma e UC para saber quantos ECTS vale esta nova inscrição
    SELECT m.curso_id, t.ano_letivo, uc.ects
    INTO v_curso_id, v_ano_letivo, v_novos_ects
    FROM matricula m
    JOIN turma t ON t.id = :NEW.turma_id
    JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
    WHERE m.id = :NEW.matricula_id
      AND uc.curso_id = m.curso_id;

    -- Somar ECTS já inscritos para este aluno, neste ano letivo e curso
    SELECT NVL(SUM(uc.ects), 0)
    INTO v_total_ects
    FROM inscricao i
    JOIN turma t ON i.turma_id = t.id
    JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
    WHERE i.matricula_id = :NEW.matricula_id
      AND t.ano_letivo = v_ano_letivo
      AND uc.curso_id = v_curso_id
      AND i.status = '1'; -- Apenas inscrições ativas contam

    -- Verificar Limite
    IF (v_total_ects + v_novos_ects) > PKG_CONSTANTES.LIMITE_ECTS_ANUAL THEN
        RAISE E_LIMITE_ECTS;
    END IF;

EXCEPTION 
    WHEN NO_DATA_FOUND THEN 
        NULL;
    WHEN E_LIMITE_ECTS THEN
        PKG_LOG.ERRO('Limite de ' || PKG_CONSTANTES.LIMITE_ECTS_ANUAL || ' ECTS anuais excedido (' || (v_total_ects + v_novos_ects) || ') para matricula ' || :NEW.matricula_id, 'INSCRICAO');
        RAISE;
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro inesperado no trigger de ECTS: ' || SQLERRM, 'INSCRICAO');
        RAISE;
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
