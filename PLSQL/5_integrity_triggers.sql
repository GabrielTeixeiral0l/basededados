-- =============================================================================
-- 5. TRIGGERS DE INTEGRIDADE E REGRAS DE NEGÓCIO
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
-- 5.2. CONFLITO DE HORÁRIO (SALA OU DOCENTE) - INSERT
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_HORARIO_AULA_INS
    BEFORE INSERT ON aula
    FOR EACH ROW
DECLARE
    v_conflito NUMBER;
    v_doc_id   NUMBER;
BEGIN
    SELECT docente_id INTO v_doc_id FROM turma WHERE id = :NEW.turma_id;
    SELECT COUNT(*) INTO v_conflito 
    FROM aula a JOIN turma t ON a.turma_id = t.id
    WHERE a.data = :NEW.data 
      AND a.status = '1'
      AND ((a.sala_id = :NEW.sala_id) OR (t.docente_id = v_doc_id))
      AND (:NEW.hora_inicio < a.hora_fim AND :NEW.hora_fim > a.hora_inicio);
    IF v_conflito > 0 THEN 
        :NEW.status := '0';
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aula (INS) rejeitada por conflito de horário.');
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.2.1. CONFLITO DE HORÁRIO (SALA OU DOCENTE) - UPDATE
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_HORARIO_AULA_UPD
    BEFORE UPDATE ON aula
    FOR EACH ROW
DECLARE
    v_conflito NUMBER;
    v_doc_id   NUMBER;
BEGIN
    SELECT docente_id INTO v_doc_id FROM turma WHERE id = :NEW.turma_id;
    SELECT COUNT(*) INTO v_conflito 
    FROM aula a JOIN turma t ON a.turma_id = t.id
    WHERE a.id != :NEW.id 
      AND a.data = :NEW.data 
      AND a.status = '1'
      AND ((a.sala_id = :NEW.sala_id) OR (t.docente_id = v_doc_id))
      AND (:NEW.hora_inicio < a.hora_fim AND :NEW.hora_fim > a.hora_inicio);
    IF v_conflito > 0 THEN 
        :NEW.status := '0';
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aula (UPD) rejeitada por conflito de horário.');
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.3. CAPACIDADE DA TURMA (VAGAS ADMINISTRATIVAS) - INSERT
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_CAPACIDADE_TURMA_INS
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
            :NEW.status := '0';
            PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Turma ' || :NEW.turma_id || ' sem vagas (INS).');
        END IF;
    END IF;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN NULL;
END;
/

-- -----------------------------------------------------------------------------
-- 5.3.1. CAPACIDADE DA TURMA (VAGAS ADMINISTRATIVAS) - UPDATE
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_CAPACIDADE_TURMA_UPD
    BEFORE UPDATE OF turma_id, status ON inscricao
    FOR EACH ROW
DECLARE
    v_max NUMBER; 
    v_ins NUMBER;
BEGIN
    IF (:OLD.turma_id != :NEW.turma_id) OR (:OLD.status = '0' AND :NEW.status = '1') THEN
        SELECT max_alunos INTO v_max FROM turma WHERE id = :NEW.turma_id;
        IF v_max IS NOT NULL THEN
            SELECT COUNT(*) INTO v_ins 
            FROM inscricao 
            WHERE turma_id = :NEW.turma_id 
              AND status = '1' 
              AND id != :NEW.id;
            IF v_ins >= v_max THEN 
                :NEW.status := '0';
                PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Turma ' || :NEW.turma_id || ' sem vagas (UPD).');
            END IF;
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
    v_nova_ects  NUMBER;
BEGIN
    SELECT estudante_id, curso_id INTO v_est_id, v_cur_id FROM matricula WHERE id = :NEW.matricula_id;
    
    SELECT unidade_curricular_id INTO v_uc_id FROM turma WHERE id = :NEW.turma_id;

    -- Validação 1: Dívidas
    IF FUN_IS_DEVEDOR(v_est_id) = 'S' THEN 
        :NEW.status := '0'; 
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Estudante devedor.'); 
    END IF;

    -- Validação 2: UC no Plano de Estudos
    SELECT COUNT(*) INTO v_existe FROM uc_curso WHERE curso_id = v_cur_id AND unidade_curricular_id = v_uc_id;
    IF v_existe = 0 THEN 
        :NEW.status := '0'; 
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('UC fora do plano de estudos.'); 
    END IF;

    -- Validação 3: Limite de ECTS Anual
    SELECT NVL(MAX(ects), 0) INTO v_nova_ects 
        FROM uc_curso uc JOIN turma t ON uc.unidade_curricular_id = t.unidade_curricular_id 
        WHERE t.id = :NEW.turma_id AND uc.curso_id = v_cur_id;

    SELECT NVL(SUM(uc.ects), 0) INTO v_total_ects 
        FROM inscricao i JOIN turma t ON i.turma_id = t.id 
        JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
        WHERE i.matricula_id = :NEW.matricula_id AND uc.curso_id = v_cur_id AND i.status = '1';

    IF (v_total_ects + v_nova_ects) > PKG_CONSTANTES.LIMITE_ECTS_ANUAL(v_cur_id) THEN 
        :NEW.status := '0'; 
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Limite de ECTS anuais excedido.'); 
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.5. CAPACIDADE DO CURSO (VAGAS ANUAIS)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_CAPACIDADE_CURSO_INS
    BEFORE INSERT ON matricula
    FOR EACH ROW
DECLARE
    v_max   NUMBER; 
    v_total NUMBER;
BEGIN
    :NEW.ano_inscricao := NVL(:NEW.ano_inscricao, TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY')));
    SELECT max_alunos INTO v_max FROM curso WHERE id = :NEW.curso_id;
    IF v_max IS NOT NULL THEN
        SELECT COUNT(*) INTO v_total 
        FROM matricula 
        WHERE curso_id = :NEW.curso_id 
          AND ano_inscricao = :NEW.ano_inscricao 
          AND status = '1';
        IF v_total >= v_max THEN 
            :NEW.status := '0'; 
            PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Curso sem vagas para o ano ' || :NEW.ano_inscricao); 
        END IF;
    END IF;
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
-- 5.6.1. AGREGAÇÃO DE NOTAS (EXECUÇÃO RECURSIVA)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_NOTA_EXECUTA_CALCULOS
    AFTER INSERT OR UPDATE ON nota
DECLARE 
    v_nota_pai     NUMBER; 
    v_pai_do_pai   NUMBER; 
    i              NUMBER; 
    j              NUMBER;
BEGIN
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
END;
/

-- -----------------------------------------------------------------------------
-- 5.7. MÉDIA GERAL E CONCLUSÃO DE CURSO
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_INSCRICAO_POST_PROCESS
    AFTER UPDATE OF nota_final ON inscricao
    FOR EACH ROW
DECLARE 
    v_media     NUMBER; 
    v_ects      NUMBER; 
    v_cur_id    NUMBER; 
    v_total_obr NUMBER; 
    v_aprov     NUMBER;
BEGIN
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
    SELECT COUNT(*) INTO v_total_obr FROM uc_curso WHERE curso_id = v_cur_id;
    SELECT COUNT(*) INTO v_aprov FROM inscricao 
    WHERE matricula_id = :NEW.matricula_id 
      AND nota_final >= PKG_CONSTANTES.NOTA_APROVACAO 
      AND status = '1';
    IF v_aprov >= v_total_obr AND v_total_obr > 0 THEN 
        UPDATE matricula SET estado_matricula_id = PKG_CONSTANTES.EST_MATRICULA_CONCLUIDA 
        WHERE id = :NEW.matricula_id; 
    END IF;
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

CREATE OR REPLACE TRIGGER TRG_AUTO_GERAR_PROPINAS 
    AFTER INSERT ON matricula 
    FOR EACH ROW
BEGIN 
    PKG_TESOURARIA.PRC_GERAR_PLANO_PAGAMENTO(:NEW.id); 
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
        :NEW.status := '0'; 
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('NIF Inválido (Estudante): ' || :NEW.nome); 
    END IF;
    IF NOT PKG_VALIDACAO.FUN_VAL_CC(:NEW.cc) THEN 
        :NEW.status := '0'; 
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('CC Inválido (Estudante): ' || :NEW.nome); 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_VAL_DOCS_DOCENTE
    BEFORE INSERT OR UPDATE ON docente
    FOR EACH ROW
BEGIN 
    IF NOT PKG_VALIDACAO.FUN_VAL_NIF(:NEW.nif) THEN 
        :NEW.status := '0'; 
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('NIF Inválido (Docente): ' || :NEW.nome); 
    END IF;
    IF NOT PKG_VALIDACAO.FUN_VAL_CC(:NEW.cc) THEN 
        :NEW.status := '0'; 
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('CC Inválido (Docente): ' || :NEW.nome); 
    END IF;
END;
/
