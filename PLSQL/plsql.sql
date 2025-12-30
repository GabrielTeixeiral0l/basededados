-- PK das tabelas
CREATE SEQUENCE seq_aula START WITH 10000;
CREATE SEQUENCE seq_avaliacao START WITH 10000;
CREATE SEQUENCE seq_curso START WITH 10000;
CREATE SEQUENCE seq_docente START WITH 10000;
CREATE SEQUENCE seq_entrega START WITH 10000;
CREATE SEQUENCE seq_estudante START WITH 10000;
CREATE SEQUENCE seq_ficheiro_entrega START WITH 10000;
CREATE SEQUENCE seq_ficheiro_recurso START WITH 10000;
CREATE SEQUENCE seq_inscricao START WITH 10000;
CREATE SEQUENCE seq_log START WITH 10000;
CREATE SEQUENCE seq_matricula START WITH 10000;
CREATE SEQUENCE seq_parcela_propina START WITH 10000;
CREATE SEQUENCE seq_recurso START WITH 10000;
CREATE SEQUENCE seq_sala START WITH 10000;
CREATE SEQUENCE seq_tipo_aula START WITH 10000;
CREATE SEQUENCE seq_tipo_avaliacao START WITH 10000;
CREATE SEQUENCE seq_tipo_curso START WITH 10000;
CREATE SEQUENCE seq_turma START WITH 10000;
CREATE SEQUENCE seq_unidade_curricular START WITH 10000;

-- Numero de aluno 
CREATE SEQUENCE seq_num_aluno START WITH 1 MAXVALUE 999999 CYCLE;


--Auto increment
CREATE OR REPLACE TRIGGER TRG_AI_AULA 
    BEFORE INSERT ON aula FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_aula.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_AVALIACAO 
    BEFORE INSERT ON avaliacao FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_avaliacao.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_CURSO 
    BEFORE INSERT ON curso FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_curso.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_DOCENTE 
    BEFORE INSERT ON docente FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_docente.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_ENTREGA 
    BEFORE INSERT ON entrega FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_entrega.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_ESTUDANTE 
    BEFORE INSERT ON estudante FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_estudante.NEXTVAL; 
    END IF;
    
    -- Número de Aluno: Ano (4 dig) + Sequência (6 dig) (LPAD: faz o preenchimento com zeros à esquerda até 6 digitos)
    IF :NEW.codigo IS NULL THEN
        :NEW.codigo := TO_CHAR(SYSDATE, 'YYYY') || LPAD(seq_num_aluno.NEXTVAL, 6, '0'); 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_FICH_ENTREGA 
    BEFORE INSERT ON ficheiro_entrega FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_ficheiro_entrega.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_FICH_RECURSO 
    BEFORE INSERT ON ficheiro_recurso FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_ficheiro_recurso.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_INSCRICAO 
    BEFORE INSERT ON inscricao FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_inscricao.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_LOG 
    BEFORE INSERT ON log FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_log.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_MATRICULA 
    BEFORE INSERT ON matricula FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_matricula.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_PARCELA 
    BEFORE INSERT ON parcela_propina FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_parcela_propina.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_RECURSO 
    BEFORE INSERT ON recurso FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_recurso.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_SALA 
    BEFORE INSERT ON sala FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_sala.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_TIPO_AULA 
    BEFORE INSERT ON tipo_aula FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_tipo_aula.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_TIPO_AVAL 
    BEFORE INSERT ON tipo_avaliacao FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_tipo_avaliacao.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_TIPO_CURSO 
    BEFORE INSERT ON tipo_curso FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_tipo_curso.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_TURMA 
    BEFORE INSERT ON turma FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_turma.NEXTVAL; 
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_AI_UC 
    BEFORE INSERT ON unidade_curricular FOR EACH ROW 
BEGIN 
    IF :NEW.id IS NULL THEN
        :NEW.id := seq_unidade_curricular.NEXTVAL; 
    END IF;
END;
/


CREATE OR REPLACE PACKAGE PKG_CONSTANTES IS

    FUNCTION VALIDACAO_RIGOROSA_NIF RETURN BOOLEAN;

    FUNCTION AUDIT_ENABLED RETURN BOOLEAN;

    FUNCTION TAXA_MULTA_ATRASO RETURN NUMBER;

    FUNCTION LIMITE_HORAS_DIARIAS_DOCENTE RETURN NUMBER;

    FUNCTION NOTA_APROVACAO RETURN NUMBER;
    FUNCTION NOTA_MINIMA RETURN NUMBER;
    FUNCTION NOTA_MAXIMA RETURN NUMBER;

    FUNCTION LIMITE_ECTS_ANUAL RETURN NUMBER;

    FUNCTION IDADE_MINIMA_ESTUDANTE RETURN NUMBER;

    FUNCTION TAMANHO_MAX_FICHEIRO RETURN NUMBER;

    FUNCTION PERCENTAGEM_PRESENCA_DEFAULT RETURN NUMBER;

    FUNCTION SOFT_DELETE_ATIVO RETURN BOOLEAN;
    

    FUNCTION MIN_PARCELAS RETURN NUMBER;
    FUNCTION MAX_PARCELAS RETURN NUMBER;
END PKG_CONSTANTES;
/

CREATE OR REPLACE PACKAGE BODY PKG_CONSTANTES IS
    -- Altere para FALSE se quiser desativar a matemática do NIF
    FUNCTION VALIDACAO_RIGOROSA_NIF RETURN BOOLEAN IS 
    BEGIN 
        RETURN FALSE; 
    END;
    
    -- Configuração de Auditoria (Logs)
    FUNCTION AUDIT_ENABLED RETURN BOOLEAN IS 
    BEGIN 
        RETURN TRUE; 
    END;

    FUNCTION TAXA_MULTA_ATRASO RETURN NUMBER IS 
    BEGIN 
        RETURN 0.10; 
    END;

    FUNCTION LIMITE_HORAS_DIARIAS_DOCENTE RETURN NUMBER IS 
    BEGIN 
        RETURN 8; 
    END;

    FUNCTION NOTA_APROVACAO RETURN NUMBER IS 
    BEGIN 
        RETURN 9.5; 
    END;

    FUNCTION NOTA_MINIMA RETURN NUMBER IS 
    BEGIN 
        RETURN 0; 
    END;

    FUNCTION NOTA_MAXIMA RETURN NUMBER IS 
    BEGIN 
        RETURN 20; 
    END;

    FUNCTION LIMITE_ECTS_ANUAL RETURN NUMBER IS 
    BEGIN 
        RETURN 60; 
    END;

    FUNCTION IDADE_MINIMA_ESTUDANTE RETURN NUMBER IS 
    BEGIN 
        RETURN 18; 
    END;

    FUNCTION TAMANHO_MAX_FICHEIRO RETURN NUMBER IS
    BEGIN
        RETURN 10485760; -- 10 MB (em Bytes)
    END;

    FUNCTION PERCENTAGEM_PRESENCA_DEFAULT RETURN NUMBER IS 
    BEGIN 
        RETURN 75; 
    END;

    FUNCTION SOFT_DELETE_ATIVO RETURN BOOLEAN IS 
    BEGIN 
        RETURN TRUE; 
    END;

    FUNCTION MIN_PARCELAS RETURN NUMBER IS 
    BEGIN 
        RETURN 1; 
    END;

    FUNCTION MAX_PARCELAS RETURN NUMBER IS 
    BEGIN 
        RETURN 12; 
    END;

END PKG_CONSTANTES;
/

--LOGS (Auditoria)
CREATE OR REPLACE PACKAGE PKG_LOG AS
    PROCEDURE REGISTAR(p_acao VARCHAR2, p_msg VARCHAR2, p_tabela VARCHAR2 DEFAULT NULL);
    PROCEDURE REGISTAR_DML(p_tabela VARCHAR2, p_acao VARCHAR2, p_id_registo VARCHAR2);
    PROCEDURE ERRO(p_msg VARCHAR2, p_tabela VARCHAR2 DEFAULT NULL);
    PROCEDURE ALERTA(p_msg VARCHAR2, p_tabela VARCHAR2 DEFAULT NULL);
END PKG_LOG;
/

CREATE OR REPLACE PACKAGE BODY PKG_LOG AS
    PROCEDURE REGISTAR(p_acao VARCHAR2, p_msg VARCHAR2, p_tabela VARCHAR2 DEFAULT NULL) IS
        -- O PRAGMA AUTONOMOUS_TRANSACTION Garante que o registo no LOG seja persistido (COMMIT) 
        -- mesmo que a transação principal (que chamou este log) sofra um ROLLBACK devido a um erro. 
        -- Essencial para auditoria e depuração.
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        -- Regista se a auditoria estiver ativa OU se for um erro crítico
        IF PKG_CONSTANTES.AUDIT_ENABLED OR p_acao = 'ERRO' THEN
            INSERT INTO log (acao, tabela, data, created_at)
            VALUES (p_acao, p_tabela, p_msg, CURRENT_TIMESTAMP);
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL; 
    END;

    PROCEDURE REGISTAR_DML(p_tabela VARCHAR2, p_acao VARCHAR2, p_id_registo VARCHAR2) IS
    BEGIN
        REGISTAR(p_acao, 'Registo ID: ' || p_id_registo, p_tabela);
    END;

    PROCEDURE ERRO(p_msg VARCHAR2, p_tabela VARCHAR2 DEFAULT NULL) IS
    BEGIN
        REGISTAR('ERRO', p_msg, p_tabela);
    END;

    PROCEDURE ALERTA(p_msg VARCHAR2, p_tabela VARCHAR2 DEFAULT NULL) IS
    BEGIN
        REGISTAR('ALERTA', p_msg, p_tabela);
    END;
END PKG_LOG;
/


-- Dois tipos de Delete (Soft e Hard)                                                                                      │
-- pode ser ativado/desativado com constante no PKG_CONSTANTES  

CREATE OR REPLACE PACKAGE PKG_GESTAO_DADOS IS
    -- Versão para tabelas com Chave Primária simples (coluna ID)
    PROCEDURE PRC_REMOVER(p_nome_tabela IN VARCHAR2, p_id IN NUMBER);

    -- Versão para tabelas de ligação ou chaves compostas
    PROCEDURE PRC_REMOVER_RELACAO(
        p_nome_tabela IN VARCHAR2, 
        p_id_1        IN NUMBER, 
        p_col_1       IN VARCHAR2,
        p_id_2        IN NUMBER,
        p_col_2       IN VARCHAR2
    );
END PKG_GESTAO_DADOS;
/

CREATE OR REPLACE PACKAGE BODY PKG_GESTAO_DADOS IS

    -- REMOÇÃO SIMPLES (PK SImples)
    PROCEDURE PRC_REMOVER(p_nome_tabela IN VARCHAR2, p_id IN NUMBER) IS
        v_sql VARCHAR2(500);
        v_tab VARCHAR2(30) := p_nome_tabela;
    BEGIN
        IF PKG_CONSTANTES.SOFT_DELETE_ATIVO THEN
            v_sql := 'UPDATE ' || v_tab || ' SET status = ''0'', updated_at = CURRENT_TIMESTAMP WHERE id = :1';
            EXECUTE IMMEDIATE v_sql USING p_id;
            
        ELSE
            v_sql := 'DELETE FROM ' || v_tab || ' WHERE id = :1';
            EXECUTE IMMEDIATE v_sql USING p_id;
        END IF;
    EXCEPTION WHEN OTHERS THEN 
        PKG_LOG.ERRO('Falha ao remover registo ID ' || p_id || ' em ' || v_tab || ': ' || SQLERRM, v_tab);
    END PRC_REMOVER;

    -- PK composta / Tabelas de Ligação
    PROCEDURE PRC_REMOVER_RELACAO(
        p_nome_tabela IN VARCHAR2, 
        p_id_1        IN NUMBER, 
        p_col_1       IN VARCHAR2,
        p_id_2        IN NUMBER,
        p_col_2       IN VARCHAR2
    ) IS
        v_sql   VARCHAR2(1000);
        v_tab   VARCHAR2(30) := p_nome_tabela;
        v_where VARCHAR2(500);
    BEGIN
        v_where := ' WHERE ' || p_col_1 || ' = :1 AND ' || p_col_2 || ' = :2';

        IF PKG_CONSTANTES.SOFT_DELETE_ATIVO THEN
            v_sql := 'UPDATE ' || v_tab || ' SET status = ''0'', updated_at = CURRENT_TIMESTAMP' || v_where;
            EXECUTE IMMEDIATE v_sql USING p_id_1, p_id_2; 
        ELSE
            v_sql := 'DELETE FROM ' || v_tab || v_where;
            EXECUTE IMMEDIATE v_sql USING p_id_1, p_id_2;
        END IF;
    EXCEPTION WHEN OTHERS THEN 
        PKG_LOG.ERRO('Falha ao remover registo em ' || v_tab || ': ' || SQLERRM, v_tab);
    END PRC_REMOVER_RELACAO;

END PKG_GESTAO_DADOS;
/



-- Validações Gerais
CREATE OR REPLACE PACKAGE PKG_VALIDACAO IS
    FUNCTION FUN_VALIDAR_NIF(p_nif IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION FUN_VALIDAR_CC(p_cc IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION FUN_VALIDAR_EMAIL(p_email IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION FUN_VALIDAR_IBAN(p_iban IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION FUN_VALIDAR_TELEMOVEL(p_telemovel IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION FUN_VALIDAR_TAMANHO_FICHEIRO(p_tamanho IN NUMBER) RETURN BOOLEAN;
    
    FUNCTION FUN_VALIDAR_STATUS(p_status IN VARCHAR2, p_tabela IN VARCHAR2) RETURN VARCHAR2;
END PKG_VALIDACAO;
/

CREATE OR REPLACE PACKAGE BODY PKG_VALIDACAO IS

    -- Validação de Status (0 ou 1)
    FUNCTION FUN_VALIDAR_STATUS(p_status IN VARCHAR2, p_tabela IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        IF p_status NOT IN ('0', '1') OR p_status IS NULL THEN
            PKG_LOG.ERRO('Status invalido (' || NVL(p_status, 'NULL') || ') na tabela ' || p_tabela || '. Forcado a 0.', p_tabela);
            RETURN '0';
        END IF;
        RETURN p_status;
    END FUN_VALIDAR_STATUS;

    FUNCTION FUN_VALIDAR_NIF(p_nif IN VARCHAR2) RETURN BOOLEAN IS
        v_nif VARCHAR2(9) := p_nif;
        v_soma NUMBER := 0;
        v_resto NUMBER;
        v_check_digit NUMBER;
        i NUMBER := 1;
    BEGIN
        -- Formato Básico (9 dígitos numéricos)
        IF LENGTH(v_nif) != 9 OR NOT REGEXP_LIKE(v_nif, '^[0-9]+$') THEN
            RETURN FALSE;
        END IF;

        -- Se não for rigorosa, o formato basta
        IF NOT PKG_CONSTANTES.VALIDACAO_RIGOROSA_NIF THEN
            RETURN TRUE;
        END IF;

        -- Algoritmo Modulo 11
        LOOP
            EXIT WHEN i > 8;
            v_soma := v_soma + TO_NUMBER(SUBSTR(v_nif, i, 1)) * (10 - i);
            i := i + 1;
        END LOOP;

        v_resto := MOD(v_soma, 11);
        v_check_digit := CASE WHEN v_resto IN (0, 1) THEN 0 ELSE 11 - v_resto END;

        RETURN v_check_digit = TO_NUMBER(SUBSTR(v_nif, 9, 1));
    EXCEPTION WHEN OTHERS THEN RETURN FALSE;
    END FUN_VALIDAR_NIF;

    FUNCTION FUN_VALIDAR_CC(p_cc IN VARCHAR2) RETURN BOOLEAN IS
        v_cc VARCHAR2(20) := UPPER(REPLACE(p_cc, ' ', ''));
    BEGIN
        RETURN REGEXP_LIKE(v_cc, '^[0-9A-Z]{12}$');
    END FUN_VALIDAR_CC;

    FUNCTION FUN_VALIDAR_EMAIL(p_email IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN REGEXP_LIKE(p_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    END FUN_VALIDAR_EMAIL;

    FUNCTION FUN_VALIDAR_IBAN(p_iban IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN LENGTH(TRIM(p_iban)) = 25 AND SUBSTR(TRIM(p_iban), 1, 2) = 'PT' 
               AND REGEXP_LIKE(SUBSTR(TRIM(p_iban), 3), '^[0-9]+$');
    END FUN_VALIDAR_IBAN;

    FUNCTION FUN_VALIDAR_TELEMOVEL(p_telemovel IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN REGEXP_LIKE(p_telemovel, '^9[0-9]{8}$');
    END FUN_VALIDAR_TELEMOVEL;

    FUNCTION FUN_VALIDAR_TAMANHO_FICHEIRO(p_tamanho IN NUMBER) RETURN BOOLEAN IS
    BEGIN
        RETURN p_tamanho > 0 AND p_tamanho <= PKG_CONSTANTES.TAMANHO_MAX_FICHEIRO;
    END FUN_VALIDAR_TAMANHO_FICHEIRO;

END PKG_VALIDACAO;
/





-- PKG para gerir buffer de matrículas 
CREATE OR REPLACE PACKAGE PKG_BUFFER_MATRICULA IS
    TYPE t_lista_ids IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    v_ids_matricula t_lista_ids;
    
    PROCEDURE LIMPAR;
    PROCEDURE ADICIONAR(p_id NUMBER);
END PKG_BUFFER_MATRICULA;
/

CREATE OR REPLACE PACKAGE BODY PKG_BUFFER_MATRICULA IS
    PROCEDURE LIMPAR IS
    BEGIN
        v_ids_matricula.DELETE;
    END;

    PROCEDURE ADICIONAR(p_id NUMBER) IS
        v_idx NUMBER;
    BEGIN
        -- Evitar duplicados simples (opcional, mas bom para performance)
        v_idx := v_ids_matricula.COUNT + 1;
        v_ids_matricula(v_idx) := p_id;
    END;
END PKG_BUFFER_MATRICULA;
/








-- Logs (para cada tabela) (chama PKG_LOG.REGISTAR_DML)

CREATE OR REPLACE TRIGGER TRG_AUDIT_AULA
    AFTER INSERT OR UPDATE OR DELETE ON AULA
    FOR EACH ROW
DECLARE
    v_id VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('AULA', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_AVALIACAO
    AFTER INSERT OR UPDATE OR DELETE ON AVALIACAO
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('AVALIACAO', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_CURSO
    AFTER INSERT OR UPDATE OR DELETE ON CURSO
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('CURSO', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_DOCENTE
    AFTER INSERT OR UPDATE OR DELETE ON DOCENTE
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('DOCENTE', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_ENTREGA
    AFTER INSERT OR UPDATE OR DELETE ON ENTREGA
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('ENTREGA', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_ESTUDANTE
    AFTER INSERT OR UPDATE OR DELETE ON ESTUDANTE
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('ESTUDANTE', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_ESTUDANTE_ENTREGA
    AFTER INSERT OR UPDATE OR DELETE ON ESTUDANTE_ENTREGA
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ENTREGA_ID) || '-' || TO_CHAR(:OLD.INSCRICAO_ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ENTREGA_ID) || '-' || TO_CHAR(:NEW.INSCRICAO_ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ENTREGA_ID) || '-' || TO_CHAR(:NEW.INSCRICAO_ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('ESTUDANTE_ENTREGA', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_FICHEIRO_ENTREGA
    AFTER INSERT OR UPDATE OR DELETE ON FICHEIRO_ENTREGA
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('FICHEIRO_ENTREGA', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_FICHEIRO_RECURSO
    AFTER INSERT OR UPDATE OR DELETE ON FICHEIRO_RECURSO
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('FICHEIRO_RECURSO', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_INSCRICAO
    AFTER INSERT OR UPDATE OR DELETE ON INSCRICAO
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('INSCRICAO', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_MATRICULA
    AFTER INSERT OR UPDATE OR DELETE ON MATRICULA
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('MATRICULA', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_NOTA
    AFTER INSERT OR UPDATE OR DELETE ON NOTA
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.AVALIACAO_ID) || '-' || TO_CHAR(:OLD.INSCRICAO_ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.AVALIACAO_ID) || '-' || TO_CHAR(:NEW.INSCRICAO_ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.AVALIACAO_ID) || '-' || TO_CHAR(:NEW.INSCRICAO_ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('NOTA', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_PARCELA_PROPINA
    AFTER INSERT OR UPDATE OR DELETE ON PARCELA_PROPINA
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('PARCELA_PROPINA', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_PRESENCA
    AFTER INSERT OR UPDATE OR DELETE ON PRESENCA
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.AULA_ID) || '-' || TO_CHAR(:OLD.INSCRICAO_ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.AULA_ID) || '-' || TO_CHAR(:NEW.INSCRICAO_ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.AULA_ID) || '-' || TO_CHAR(:NEW.INSCRICAO_ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('PRESENCA', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_RECURSO
    AFTER INSERT OR UPDATE OR DELETE ON RECURSO
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('RECURSO', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_SALA
    AFTER INSERT OR UPDATE OR DELETE ON SALA
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('SALA', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_TIPO_AULA
    AFTER INSERT OR UPDATE OR DELETE ON TIPO_AULA
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('TIPO_AULA', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_TIPO_AVALIACAO
    AFTER INSERT OR UPDATE OR DELETE ON TIPO_AVALIACAO
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('TIPO_AVALIACAO', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_TIPO_CURSO
    AFTER INSERT OR UPDATE OR DELETE ON TIPO_CURSO
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('TIPO_CURSO', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_TURMA
    AFTER INSERT OR UPDATE OR DELETE ON TURMA
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('TURMA', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_UC_CURSO
    AFTER INSERT OR UPDATE OR DELETE ON UC_CURSO
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.CURSO_ID) || '-' || TO_CHAR(:OLD.UNIDADE_CURRICULAR_ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.CURSO_ID) || '-' || TO_CHAR(:NEW.UNIDADE_CURRICULAR_ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.CURSO_ID) || '-' || TO_CHAR(:NEW.UNIDADE_CURRICULAR_ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('UC_CURSO', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_UC_DOCENTE
    AFTER INSERT OR UPDATE OR DELETE ON UC_DOCENTE
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.UNIDADE_CURRICULAR_ID) || '-' || TO_CHAR(:OLD.DOCENTE_ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.UNIDADE_CURRICULAR_ID) || '-' || TO_CHAR(:NEW.DOCENTE_ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.UNIDADE_CURRICULAR_ID) || '-' || TO_CHAR(:NEW.DOCENTE_ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('UC_DOCENTE', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_UNIDADE_CURRICULAR
    AFTER INSERT OR UPDATE OR DELETE ON UNIDADE_CURRICULAR
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('UNIDADE_CURRICULAR', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


CREATE OR REPLACE TRIGGER TRG_AUDIT_FICHEIRO_RECURSO
    AFTER INSERT OR UPDATE OR DELETE ON FICHEIRO_RECURSO
    FOR EACH ROW
DECLARE
    v_id   VARCHAR2(255);
    v_acao VARCHAR2(20);
BEGIN
    IF DELETING THEN
        v_id   := TO_CHAR(:OLD.ID);
        v_acao := 'DELETE';
    ELSIF UPDATING THEN
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'UPDATE';
    ELSE
        v_id   := TO_CHAR(:NEW.ID);
        v_acao := 'INSERT';
    END IF;
    PKG_LOG.REGISTAR_DML('FICHEIRO_RECURSO', v_acao, v_id);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/





-- Buffer para cálculo de notas finais
CREATE OR REPLACE PACKAGE PKG_BUFFER_NOTA IS
    -- Listas simples de números (Arrays)
    TYPE t_lista_numeros IS TABLE OF NUMBER;

    -- Listas para guardar os pares (Inscrição, Avaliação Pai)
    v_ids_inscricao t_lista_numeros := t_lista_numeros();
    v_ids_pais      t_lista_numeros := t_lista_numeros();
    
    -- Lista para guardar inscrições que precisam de nota final
    v_ids_finais    t_lista_numeros := t_lista_numeros();

    -- Flag para evitar recursividade nos triggers
    g_a_calcular BOOLEAN := FALSE;

    PROCEDURE ADICIONAR_PAI(p_insc_id IN NUMBER, p_pai_id IN NUMBER);
    PROCEDURE ADICIONAR_FINAL(p_insc_id IN NUMBER);
    PROCEDURE LIMPAR;
END PKG_BUFFER_NOTA;
/

CREATE OR REPLACE PACKAGE BODY PKG_BUFFER_NOTA IS

    PROCEDURE ADICIONAR_PAI(p_insc_id IN NUMBER, p_pai_id IN NUMBER) IS
    BEGIN
        -- Adiciona ao final da lista (Simples e direto)
        v_ids_inscricao.EXTEND;
        v_ids_pais.EXTEND;
        
        v_ids_inscricao(v_ids_inscricao.LAST) := p_insc_id;
        v_ids_pais(v_ids_pais.LAST) := p_pai_id;
    END ADICIONAR_PAI;

    PROCEDURE ADICIONAR_FINAL(p_insc_id IN NUMBER) IS
    BEGIN
        v_ids_finais.EXTEND;
        v_ids_finais(v_ids_finais.LAST) := p_insc_id;
    END ADICIONAR_FINAL;

    PROCEDURE LIMPAR IS
    BEGIN
        -- Esvazia as listas
        v_ids_inscricao.DELETE;
        v_ids_pais.DELETE;
        v_ids_finais.DELETE;
    END LIMPAR;

END PKG_BUFFER_NOTA;
/




-- Buffer para gerir lista de inscrições a processar
CREATE OR REPLACE PACKAGE PKG_BUFFER_INSCRICAO IS
    TYPE r_insc IS RECORD (
        matricula_id NUMBER,
        turma_id     NUMBER,
        uc_id        NUMBER,
        ects         NUMBER,
        ano_letivo   VARCHAR2(10),
        curso_id     NUMBER
    );
    TYPE t_insc IS TABLE OF r_insc;
    
    v_lista_inscricoes t_insc := t_insc();

    PROCEDURE LIMPAR;
    PROCEDURE ADICIONAR(
        p_mat_id NUMBER, 
        p_tur_id NUMBER, 
        p_uc_id NUMBER, 
        p_ects NUMBER, 
        p_ano VARCHAR2, 
        p_cur_id NUMBER
    );
END PKG_BUFFER_INSCRICAO;
/

CREATE OR REPLACE PACKAGE BODY PKG_BUFFER_INSCRICAO IS
    PROCEDURE LIMPAR IS
    BEGIN
        v_lista_inscricoes.DELETE;
    END;

    PROCEDURE ADICIONAR(
        p_mat_id NUMBER, 
        p_tur_id NUMBER, 
        p_uc_id NUMBER, 
        p_ects NUMBER, 
        p_ano VARCHAR2, 
        p_cur_id NUMBER
    ) IS
    BEGIN
        v_lista_inscricoes.EXTEND;
        v_lista_inscricoes(v_lista_inscricoes.LAST).matricula_id := p_mat_id;
        v_lista_inscricoes(v_lista_inscricoes.LAST).turma_id := p_tur_id;
        v_lista_inscricoes(v_lista_inscricoes.LAST).uc_id := p_uc_id;
        v_lista_inscricoes(v_lista_inscricoes.LAST).ects := p_ects;
        v_lista_inscricoes(v_lista_inscricoes.LAST).ano_letivo := p_ano;
        v_lista_inscricoes(v_lista_inscricoes.LAST).curso_id := p_cur_id;
    END;
END PKG_BUFFER_INSCRICAO;
/





-- tesouraria 
CREATE OR REPLACE PACKAGE PKG_TESOURARIA IS
    PROCEDURE PRC_GERAR_PLANO_PAGAMENTO(
        p_matricula_id IN NUMBER, 
        p_valor_total IN NUMBER DEFAULT NULL, 
        p_num_parcelas IN NUMBER DEFAULT NULL
    );
    PROCEDURE PRC_PROCESSAR_PAGAMENTO(p_parcela_id IN NUMBER, p_valor IN NUMBER);
END PKG_TESOURARIA;
/

CREATE OR REPLACE PACKAGE BODY PKG_TESOURARIA IS

    PROCEDURE PRC_GERAR_PLANO_PAGAMENTO(
        p_matricula_id IN NUMBER, 
        p_valor_total IN NUMBER DEFAULT NULL, 
        p_num_parcelas IN NUMBER DEFAULT NULL
    ) IS
        v_num_parcelas NUMBER := p_num_parcelas; 
        v_valor_total NUMBER := p_valor_total; 
        v_valor_parcela NUMBER; 
        v_pagas NUMBER; 
        i NUMBER := 1;
    BEGIN
        
        -- Verificar se já existem pagamentos para não sobrescrever plano ativo com histórico
        SELECT COUNT(*) INTO v_pagas FROM parcela_propina WHERE matricula_id = p_matricula_id AND estado = '1';
        IF v_pagas > 0 THEN 
            PKG_LOG.ALERTA('Plano de pagamento não gerado: Já existem parcelas pagas.', 'PARCELA_PROPINA');
            RETURN; 
        END IF;

        DELETE FROM parcela_propina WHERE matricula_id = p_matricula_id;

        -- Se os valores não foram passados (chamada manual), busca na base
        IF v_valor_total IS NULL OR v_num_parcelas IS NULL THEN
            SELECT tc.valor_propinas, m.numero_parcelas 
            INTO v_valor_total, v_num_parcelas
            FROM matricula m 
            JOIN curso c ON m.curso_id = c.id 
            JOIN tipo_curso tc ON c.tipo_curso_id = tc.id 
            WHERE m.id = p_matricula_id;
        END IF;

        DBMS_OUTPUT.PUT_LINE('Valor Total: ' || v_valor_total || ', Parcelas: ' || v_num_parcelas);

        IF v_num_parcelas <= 0 THEN 
            DBMS_OUTPUT.PUT_LINE('Número de parcelas inválido.');
            RETURN; 
        END IF;

        v_valor_parcela := v_valor_total / v_num_parcelas;

        LOOP
            EXIT WHEN i > v_num_parcelas;
            INSERT INTO parcela_propina (valor, data_vencimento, numero, estado, matricula_id, status)
            VALUES (v_valor_parcela, ADD_MONTHS(SYSDATE, i), i, '0', p_matricula_id, '1');
            i := i + 1;
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('Plano gerado com sucesso: ' || v_num_parcelas || ' parcelas.');
        
    EXCEPTION 
        WHEN OTHERS THEN 
            PKG_LOG.ERRO('PKG_TESOURARIA.PRC_GERAR_PLANO_PAGAMENTO: ' || SQLERRM, 'PARCELA_PROPINA');
            RAISE;
    END PRC_GERAR_PLANO_PAGAMENTO;

    PROCEDURE PRC_PROCESSAR_PAGAMENTO(p_parcela_id IN NUMBER, p_valor IN NUMBER) IS
        v_vencimento DATE; 
        v_orig NUMBER; 
        v_multa NUMBER := 0;
    BEGIN
        SELECT data_vencimento, valor INTO v_vencimento, v_orig FROM parcela_propina WHERE id = p_parcela_id;
        IF SYSDATE > v_vencimento THEN
            v_multa := v_orig * PKG_CONSTANTES.TAXA_MULTA_ATRASO;
            PKG_LOG.ALERTA('Multa de ' || v_multa || ' aplicada.', 'PARCELA_PROPINA');
        END IF;
        UPDATE parcela_propina SET estado = '1', data_pagamento = SYSDATE, valor = v_orig + v_multa, updated_at = SYSDATE WHERE id = p_parcela_id;
    EXCEPTION 
        WHEN OTHERS THEN 
            PKG_LOG.ERRO('PKG_TESOURARIA.PRC_PROCESSAR_PAGAMENTO: ' || SQLERRM, 'PARCELA_PROPINA');
    END PRC_PROCESSAR_PAGAMENTO;
END PKG_TESOURARIA;
/




-- Triggers de integridade e regras de negócio

-- VALIDAÇÃO DE NOTAS (Status, Limites e Integridade de Turma)
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
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'NOTA');

    -- 2. Validar Limites (0 a 20)
    IF :NEW.nota < 0 OR :NEW.nota > 20 THEN
        RAISE E_NOTA_INVALIDA;
    END IF;

    -- 3. Validar Consistência de Turma (A inscrição e a avaliação devem pertencer à mesma turma)
    SELECT turma_id INTO v_turma_inscricao FROM inscricao WHERE id = :NEW.inscricao_id;
    SELECT turma_id INTO v_turma_avaliacao FROM avaliacao WHERE id = :NEW.avaliacao_id;

    IF v_turma_inscricao != v_turma_avaliacao THEN
        RAISE E_TURMA_INCONSISTENTE;
    END IF;

EXCEPTION
    WHEN E_NOTA_INVALIDA THEN 
        PKG_LOG.ERRO('Tentativa de inserir nota invalida: ' || :NEW.nota || ' para inscricao ' || :NEW.inscricao_id, 'NOTA');
        RAISE;
    WHEN E_TURMA_INCONSISTENTE THEN 
        PKG_LOG.ERRO('Inconsistencia: A inscricao ' || :NEW.inscricao_id || ' (Turma ' || v_turma_inscricao ||  ') nao pertence a turma da avaliacao ' || :NEW.avaliacao_id || ' (Turma ' || v_turma_avaliacao || ').', 'NOTA');
        RAISE;
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro desconhecido na validacao de nota: ' || SQLERRM, 'NOTA');
        RAISE;
END;
/

-- CALCULO DE MÉDIAS
-- 1 - CÁLCULO DE MÉDIAS - TRIGGER 1: INICIALIZAÇÃO
CREATE OR REPLACE TRIGGER TRG_NOTA_MEDIA_BS
BEFORE INSERT OR UPDATE ON NOTA
BEGIN
    PKG_BUFFER_NOTA.LIMPAR;
END;
/

-- 2 - CÁLCULO DE MÉDIAS - TRIGGER 2: Verificação e Armazenamento
CREATE OR REPLACE TRIGGER TRG_NOTA_MEDIA_AR
AFTER INSERT OR UPDATE ON NOTA
FOR EACH ROW
DECLARE
    v_pai_id NUMBER;
BEGIN
    IF NOT PKG_BUFFER_NOTA.g_a_calcular THEN
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

-- 3 - CÁLCULO DE MÉDIAS - TRIGGER 3: PROCESSAMENTO 
CREATE OR REPLACE TRIGGER TRG_NOTA_MEDIA_AS
AFTER INSERT OR UPDATE ON NOTA
DECLARE
    v_nota_final NUMBER;
    v_idx NUMBER;
    v_ins_id NUMBER;
    v_pai_id NUMBER;
    CURSOR c_calculo(p_ins_id NUMBER, p_pai_id NUMBER) IS
        SELECT NVL(SUM(n.nota * a.peso), 0) -- peso pode ser null 
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
            SET nota = v_nota_final
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
EXCEPTION 
    WHEN OTHERS THEN
        PKG_BUFFER_NOTA.g_a_calcular := FALSE;
        IF c_calculo%ISOPEN THEN CLOSE c_calculo; END IF;
        PKG_LOG.ERRO('Erro no processamento de medias: '||SQLERRM, 'NOTA');
END;
/

-- GERAÇÃO AUTOMÁTICA DE PRESENÇAS (AO INSCREVER ALUNO)
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
EXCEPTION 
    WHEN OTHERS THEN
        IF c_aulas%ISOPEN THEN CLOSE c_aulas; END IF;
        PKG_LOG.ERRO('Erro ao gerar presenças automáticas para inscrição ' || :NEW.id || ': ' || SQLERRM, 'PRESENCA');
        RAISE;
END;
/

-- GERAÇÃO AUTOMÁTICA DE PRESENÇAS (AO CRIAR NOVA AULA)
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

-- VALIDAÇÃO DE REGRAS DE AVALIAÇÃO
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
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'AVALIACAO');

    -- 2. Validar Peso (0 a 1)
    IF :NEW.peso < 0 OR :NEW.peso > 1 THEN
        PKG_LOG.ERRO('Peso invalido (' || :NEW.peso || ') na avaliacao. Ajustado para 0.', 'AVALIACAO');
        :NEW.peso := 0;
    END IF;

    -- 3. Obter regras do Tipo de Avaliação
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

    -- 4. Validar Hierarquia (Pai)
    IF :NEW.avaliacao_pai_id IS NOT NULL THEN
        SELECT t.permite_filhos INTO v_pai_permite_filhos
        FROM avaliacao a
        JOIN tipo_avaliacao t ON a.tipo_avaliacao_id = t.id
        WHERE a.id = :NEW.avaliacao_pai_id;

        IF v_pai_permite_filhos = '0' THEN
             PKG_LOG.ERRO('A avaliacao pai ' || :NEW.avaliacao_pai_id || ' nao permite sub-avaliacoes.', 'AVALIACAO');
             RAISE E_PAI_INVALIDO;
        END IF;
    END IF;
END;
/

-- VALIDAÇÃO DE LIMITE DE GRUPO NA ENTREGA
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

-- VALIDAÇÃO DE REGRAS DE ASSOCIAÇÃO (ESTUDANTE_ENTREGA)
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
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'ESTUDANTE_ENTREGA');

    -- Obter dados da Entrega/Avaliação
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
         PKG_LOG.ERRO('Inconsistencia: Inscricao ' || :NEW.inscricao_id || ' pertence a turma ' || v_turma_inscricao || ' mas a entrega e da turma ' || v_turma_entrega, 'ESTUDANTE_ENTREGA');
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
         PKG_LOG.ERRO('A inscricao ' || :NEW.inscricao_id || ' ja esta associada a um grupo nesta avaliacao.', 'ESTUDANTE_ENTREGA');
         RAISE E_DUPLICADO;
    END IF;

EXCEPTION
    WHEN E_INCONSISTENCIA OR E_DUPLICADO THEN RAISE;
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro na validacao de estudante_entrega: ' || SQLERRM, 'ESTUDANTE_ENTREGA');
        RAISE;
END;
/

-- VALIDAÇÃO DE ENTREGAS
CREATE OR REPLACE TRIGGER TRG_VAL_ENTREGA_REGRAS
BEFORE INSERT OR UPDATE ON ENTREGA
FOR EACH ROW
DECLARE
    v_req_entrega CHAR(1);
    v_data_inicio DATE;
    v_data_fim    DATE;
BEGIN
    -- 1. Validar Status
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'ENTREGA');

    -- 2. Obter dados da Avaliação
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

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        PKG_LOG.ERRO('Avaliacao ID ' || :NEW.avaliacao_id || ' nao encontrada ao validar entrega.', 'ENTREGA');
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro na validacao de entrega: ' || SQLERRM, 'ENTREGA');
END;
/

-- VALIDAÇÃO DE DADOS (ESTUDANTE E DOCENTE)
CREATE OR REPLACE TRIGGER TRG_VAL_DADOS_ESTUDANTE
BEFORE INSERT OR UPDATE ON ESTUDANTE
FOR EACH ROW
DECLARE
    E_DADOS_INVALIDOS EXCEPTION;
BEGIN
    -- 1. Validar Status
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'ESTUDANTE');

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
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'DOCENTE');

    -- 2. Validar Data de Contratação (Não pode ser futura)
    IF :NEW.data_contratacao > SYSDATE THEN
        PKG_LOG.ERRO('Data de contratacao no futuro: ' || TO_CHAR(:NEW.data_contratacao, 'DD/MM/YYYY'), 'DOCENTE');
        RAISE E_DADOS_INVALIDOS;
    END IF;

    -- 3. Validar Identidade e Contactos
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

-- VALIDAÇÃO DE HORÁRIOS DE AULA (Conflitos de Sala e Docente)
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
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'AULA');

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

-- VALIDAÇÃO DE INSCRIÇÃO (SISTEMA DE 3 TRIGGERS)

-- 1. Inicialização
CREATE OR REPLACE TRIGGER TRG_INSCRICAO_BS
BEFORE INSERT OR UPDATE ON INSCRICAO
BEGIN
    PKG_BUFFER_INSCRICAO.LIMPAR;
END;
/

-- 2. Captura de Dados (Before Each Row)
CREATE OR REPLACE TRIGGER TRG_INSCRICAO_AR
BEFORE INSERT OR UPDATE ON INSCRICAO
FOR EACH ROW
DECLARE
    v_c_id NUMBER; v_u_id NUMBER; v_e NUMBER; v_ano VARCHAR2(10);
    E_FORA_PLANO EXCEPTION;
BEGIN
    -- 1. validar status
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'INSCRICAO');

    -- 2. Obter Dados de Contexto (Turma/Curso/ECTS)
    SELECT t.unidade_curricular_id, m.curso_id, uc.ects, t.ano_letivo
    INTO v_u_id, v_c_id, v_e, v_ano
    FROM turma t
    JOIN matricula m ON m.id = :NEW.matricula_id
    JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
    WHERE t.id = :NEW.turma_id AND uc.curso_id = m.curso_id;

    -- 3. Guardar para validação em lote (After Statement)
    PKG_BUFFER_INSCRICAO.ADICIONAR(:NEW.matricula_id, :NEW.turma_id, v_u_id, v_e, v_ano, v_c_id);

EXCEPTION 
    WHEN NO_DATA_FOUND THEN
        PKG_LOG.ERRO('UC fora do plano de estudos ou dados invalidos para a inscricao.', 'INSCRICAO');
        RAISE E_FORA_PLANO;
    WHEN E_FORA_PLANO THEN
        RAISE;
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro inesperado em TRG_INSCRICAO_AR: ' || SQLERRM, 'INSCRICAO');
        RAISE;
END;
/

-- 3. Processamento e Validação Final
CREATE OR REPLACE TRIGGER TRG_INSCRICAO_AS
AFTER INSERT OR UPDATE ON INSCRICAO
DECLARE
    v_total_ects NUMBER;
    v_count NUMBER;
    E_DUPLICADO EXCEPTION;
    E_LIMITE_ECTS EXCEPTION;
BEGIN
    IF PKG_BUFFER_INSCRICAO.v_lista_inscricoes.COUNT > 0 THEN
        FOR i IN 1..PKG_BUFFER_INSCRICAO.v_lista_inscricoes.COUNT LOOP
            -- 4. Validar Duplicados (Mesma UC)
            SELECT COUNT(*) INTO v_count 
            FROM inscricao ins 
            JOIN turma t ON ins.turma_id = t.id
            WHERE ins.matricula_id = PKG_BUFFER_INSCRICAO.v_lista_inscricoes(i).matricula_id 
              AND t.unidade_curricular_id = PKG_BUFFER_INSCRICAO.v_lista_inscricoes(i).uc_id 
              AND ins.status = '1';
            
            IF v_count > 1 THEN 
                PKG_LOG.ERRO('Inscricao duplicada na mesma disciplina detetada.', 'INSCRICAO');
                RAISE E_DUPLICADO; 
            END IF;

            -- 5. Validar Limite de ECTS
            SELECT NVL(SUM(uc.ects), 0) INTO v_total_ects
            FROM inscricao ins
            JOIN turma t ON ins.turma_id = t.id
            JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
            WHERE ins.matricula_id = PKG_BUFFER_INSCRICAO.v_lista_inscricoes(i).matricula_id 
              AND t.ano_letivo = PKG_BUFFER_INSCRICAO.v_lista_inscricoes(i).ano_letivo
              AND uc.curso_id = PKG_BUFFER_INSCRICAO.v_lista_inscricoes(i).curso_id 
              AND ins.status = '1';

            IF v_total_ects > PKG_CONSTANTES.LIMITE_ECTS_ANUAL THEN
                PKG_LOG.ERRO('Limite de '||PKG_CONSTANTES.LIMITE_ECTS_ANUAL||' ECTS excedido (Total: '||v_total_ects||').', 'INSCRICAO');
                RAISE E_LIMITE_ECTS;
            END IF;
        END LOOP;
        
        PKG_BUFFER_INSCRICAO.LIMPAR;
    END IF;
EXCEPTION
    WHEN E_DUPLICADO OR E_LIMITE_ECTS THEN RAISE;
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro no processamento final de inscricoes: '||SQLERRM, 'INSCRICAO');
        RAISE;
END;
/

--  ATUALIZAÇÃO AUTOMÁTICA DA MÉDIA GERAL (SISTEMA DE 3 TRIGGERS)

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
    PKG_LOG.ERRO('Erro no calculo de media: ' || SQLERRM, 'MATRICULA');
END;
/

-- VALIDAÇÃO DE MATRÍCULA (DUPLICIDADE, PARCELAS E STATUS)
CREATE OR REPLACE TRIGGER TRG_VAL_MATRICULA
BEFORE INSERT OR UPDATE ON MATRICULA
FOR EACH ROW
DECLARE
    E_DUPLICADO EXCEPTION;
    E_PARCELAS_INVALIDAS EXCEPTION;
    v_count NUMBER;
BEGIN
    -- 1. Validar Status
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'MATRICULA');

    -- 2. Validar Número de Parcelas (Min 1, Max 12)
    IF :NEW.numero_parcelas < PKG_CONSTANTES.MIN_PARCELAS OR :NEW.numero_parcelas > PKG_CONSTANTES.MAX_PARCELAS THEN
        PKG_LOG.ERRO('Numero de parcelas invalido ('||:NEW.numero_parcelas||'). Deve ser entre '||
                     PKG_CONSTANTES.MIN_PARCELAS||' e '||PKG_CONSTANTES.MAX_PARCELAS, 'MATRICULA');
        RAISE E_PARCELAS_INVALIDAS;
    END IF;

    -- 3. Impedir Matrícula Ativa duplicada no mesmo Curso
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

-- GERAR PROPINAS AUTOMATICAMENTE AO MATRICULAR
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

-- VALIDAÇÃO DE SALA (STATUS E CAPACIDADE)
CREATE OR REPLACE TRIGGER TRG_VAL_SALA
BEFORE INSERT OR UPDATE ON SALA
FOR EACH ROW
BEGIN
    -- 1. Validar Status (0 ou 1)
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'SALA');

    -- 2. Garantir Capacidade Positiva
    IF :NEW.capacidade <= 0 OR :NEW.capacidade IS NULL THEN
        PKG_LOG.ERRO('Capacidade invalida (' || NVL(TO_CHAR(:NEW.capacidade), 'NULL') || ') na sala ' || :NEW.nome || '. Forcada a 1.', 'SALA');
        :NEW.capacidade := 1;
    END IF;
END;
/

-- VALIDAÇÃO DE CURSO (STATUS, DURACAO, ECTS)
CREATE OR REPLACE TRIGGER TRG_VAL_CURSO
BEFORE INSERT OR UPDATE ON CURSO
FOR EACH ROW
BEGIN
    -- 1. Validar Status
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'CURSO');

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

-- VALIDAÇÃO DE FICHEIRO DE ENTREGA (STATUS E TAMANHO)
CREATE OR REPLACE TRIGGER TRG_VAL_FICHEIRO_ENTREGA
BEFORE INSERT OR UPDATE ON FICHEIRO_ENTREGA
FOR EACH ROW
DECLARE
    E_TAMANHO_INVALIDO EXCEPTION;
BEGIN
    -- 1. Validar Status
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'FICHEIRO_ENTREGA');

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

-- VALIDAÇÃO DE FICHEIRO DE RECURSO (STATUS E TAMANHO) TABELA TEM QUE SER ALTERADA
CREATE OR REPLACE TRIGGER TRG_VAL_FICHEIRO_RECURSO
BEFORE INSERT OR UPDATE ON FICHEIRO_RECURSO
FOR EACH ROW
DECLARE
    E_TAMANHO_INVALIDO EXCEPTION;
BEGIN
    -- 1. Validar Status
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'FICHEIRO_RECURSO');

    -- 2. Validar Tamanho (obtendo o tamanho do BLOB)
    IF NOT PKG_VALIDACAO.FUN_VALIDAR_TAMANHO_FICHEIRO(:NEW.tamanho) THEN
        PKG_LOG.ERRO('Tamanho de ficheiro de recurso invalido: ' || NVL(TO_CHAR(:NEW.tamanho), 'NULL') || 
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

--PROTEÇÃO DA TABELA DE LOGS (IMUTABILIDADE COM RASTO)
CREATE OR REPLACE TRIGGER TRG_PROTEGER_LOG
BEFORE DELETE OR UPDATE ON LOG
FOR EACH ROW
DECLARE
    E_IMUTAVEL EXCEPTION;
    v_operacao VARCHAR2(20);
BEGIN
    
    v_operacao := CASE WHEN DELETING THEN 'DELETE' ELSE 'UPDATE' END;
    
    PKG_LOG.REGISTAR('VIOLACAO_SEGURANCA', 
                        'Tentativa de ' || v_operacao || ' no log id: ' || :OLD.id, 
                        'LOG');
    
    RAISE E_IMUTAVEL;
  
END;
/


-- VALIDAÇÃO DE PARCELA DE PROPINA
CREATE OR REPLACE TRIGGER TRG_VAL_PARCELA_PROPINA
BEFORE INSERT OR UPDATE ON PARCELA_PROPINA
FOR EACH ROW
DECLARE
    v_total_curso NUMBER;
    v_num_parcelas NUMBER;
    v_mat_id NUMBER;
    E_DADOS_INVALIDOS EXCEPTION;
BEGIN
    -- 1. Validar Status 
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.estado, 'PARCELA_PROPINA');

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

-- VALIDAÇÃO DE PRESENÇA (Integridade Académica)
CREATE OR REPLACE TRIGGER TRG_VAL_PRESENCA
BEFORE INSERT OR UPDATE ON PRESENCA
FOR EACH ROW
DECLARE
    E_DADOS_INVALIDOS EXCEPTION;
BEGIN
    -- 1. Validar Status
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'PRESENCA');

    -- 2. Validar valor do campo presente ('0' ou '1')
    IF :NEW.presente NOT IN ('0', '1') THEN
        :NEW.presente := '0'; 
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        PKG_LOG.ERRO('Erro na validacao de presenca: ' || SQLERRM, 'PRESENCA');
        RAISE;
END;
/


-- VALIDAÇÃO DE RECURSO
CREATE OR REPLACE TRIGGER TRG_VAL_RECURSO
BEFORE INSERT OR UPDATE ON RECURSO
FOR EACH ROW
DECLARE
    v_turma_docente NUMBER;
    E_DOCENTE_NAO_TURMA EXCEPTION;
BEGIN
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'RECURSO');

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


-- VALIDAÇÃO DE TIPO_AULA E TIPO_AVALIACAO
CREATE OR REPLACE TRIGGER TRG_VAL_TIPO_AULA
BEFORE INSERT OR UPDATE ON TIPO_AULA
FOR EACH ROW
BEGIN
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'TIPO_AULA');
END;
/

CREATE OR REPLACE TRIGGER TRG_VAL_TIPO_AVALIACAO
BEFORE INSERT OR UPDATE ON TIPO_AVALIACAO
FOR EACH ROW
BEGIN
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'TIPO_AVALIACAO');
    
    IF :NEW.requer_entrega NOT IN ('0','1') THEN :NEW.requer_entrega := '0'; END IF;
    IF :NEW.permite_grupo NOT IN ('0','1') THEN :NEW.permite_grupo := '0'; END IF;
    IF :NEW.permite_filhos NOT IN ('0','1') THEN :NEW.permite_filhos := '0'; END IF;
END;
/


-- VALIDAÇÃO DE TIPO_CURSO E UNIDADE_CURRICULAR
CREATE OR REPLACE TRIGGER TRG_VAL_TIPO_CURSO
BEFORE INSERT OR UPDATE ON TIPO_CURSO
FOR EACH ROW
BEGIN
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'TIPO_CURSO');
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
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'UNIDADE_CURRICULAR');
    IF :NEW.horas_teoricas < 0 THEN :NEW.horas_teoricas := 0; END IF;
    IF :NEW.horas_praticas < 0 THEN :NEW.horas_praticas := 0; END IF;
END;
/


-- VALIDAÇÃO DE TURMA
CREATE OR REPLACE TRIGGER TRG_VAL_TURMA
BEFORE INSERT OR UPDATE ON TURMA
FOR EACH ROW
DECLARE
    v_exists NUMBER;
    E_DOCENTE_INVALIDO EXCEPTION;
BEGIN
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'TURMA');

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

-- VALIDAÇÃO DE UC_CURSO 
CREATE OR REPLACE TRIGGER TRG_VAL_UC_CURSO
BEFORE INSERT OR UPDATE ON UC_CURSO
FOR EACH ROW
DECLARE
    v_duracao_curso NUMBER;
    E_DURACAO_EXCEDIDA EXCEPTION;
    E_PRESENCA_INVALIDA EXCEPTION;
BEGIN
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'UC_CURSO');
    
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

-- VALIDAÇÃO DE UC_DOCENTE
CREATE OR REPLACE TRIGGER TRG_VAL_UC_DOCENTE
BEFORE INSERT OR UPDATE ON UC_DOCENTE
FOR EACH ROW
BEGIN
    :NEW.status := PKG_VALIDACAO.FUN_VALIDAR_STATUS(:NEW.status, 'UC_DOCENTE');
END;
/




CREATE OR REPLACE FUNCTION FUN_GET_ASSIDUIDADE(p_inscricao_id IN NUMBER) RETURN NUMBER IS
    v_total      NUMBER;
    v_presencas  NUMBER;
BEGIN
    -- 1. Obter o número total de aulas
    SELECT COUNT(*) 
    INTO v_total
    FROM presenca
    WHERE inscricao_id = p_inscricao_id AND status = '1';

    -- Se não houver aulas, evita divisão por zero
    IF v_total = 0 THEN
        RETURN 0;
    END IF;

    -- 2. Obter o número de presenças
    SELECT COUNT(*) 
    INTO v_presencas
    FROM presenca
    WHERE inscricao_id = p_inscricao_id 
      AND status = '1'
      AND presente = '1';

    -- 3. Calcular a percentagem
    RETURN ROUND((v_presencas / v_total) * 100, 2);

EXCEPTION 
    WHEN OTHERS THEN 
        RETURN 0;
END;
/


-- VIEWS


-- PAUTA POR TURMA
-- Mostra notas finais e o estado de aprovação
CREATE OR REPLACE VIEW VW_PAUTA_TURMA AS
SELECT 
    t.nome as TURMA,
    uc.nome as UNIDADE_CURRICULAR,
    e.codigo as CODIGO_ALUNO,
    e.nome as NOME_ESTUDANTE,
    i.nota_final as NOTA_FINAL,
    CASE 
        WHEN i.nota_final >= PKG_CONSTANTES.NOTA_APROVACAO THEN 'APROVADO'
        ELSE 'REPROVADO'
    END as RESULTADO
FROM inscricao i
JOIN turma t ON i.turma_id = t.id
JOIN unidade_curricular uc ON t.unidade_curricular_id = uc.id
JOIN matricula m ON i.matricula_id = m.id
JOIN estudante e ON m.estudante_id = e.id
WHERE i.status = '1';
/


-- ALERTAS DE ASSIDUIDADE
-- Identifica alunos em risco de reprovação por faltas.
CREATE OR REPLACE VIEW VW_ALERTA_ASSIDUIDADE AS
SELECT 
    e.nome as NOME_ESTUDANTE,
    t.nome as NOME_TURMA,
    (100 - FUN_GET_ASSIDUIDADE(i.id)) as PERC_FALTAS
FROM inscricao i
JOIN matricula m ON i.matricula_id = m.id
JOIN estudante e ON m.estudante_id = e.id
JOIN turma t ON i.turma_id = t.id
WHERE i.status = '1'
  AND (100 - FUN_GET_ASSIDUIDADE(i.id)) > 25;
/


-- PERFIL ACADÉMICO DO ALUNO
-- Resumo de ECTS conquistados e média global do curso.
CREATE OR REPLACE VIEW VW_PERFIL_ACADEMICO_ALUNO AS
SELECT 
    e.codigo AS num_mecanografico,
    e.nome AS nome_estudante,
    c.nome AS nome_curso,
    COUNT(i.id) AS total_ucs_inscritas,
    SUM(CASE WHEN i.nota_final >= PKG_CONSTANTES.NOTA_APROVACAO THEN ucc.ects ELSE 0 END) AS ects_concluidos,
    ROUND(AVG(i.nota_final), 2) AS media_global
FROM estudante e
JOIN matricula m ON e.id = m.estudante_id
JOIN curso c ON m.curso_id = c.id
LEFT JOIN inscricao i ON m.id = i.matricula_id
LEFT JOIN turma t ON i.turma_id = t.id
LEFT JOIN unidade_curricular uc ON t.unidade_curricular_id = uc.id
LEFT JOIN uc_curso ucc ON uc.id = ucc.unidade_curricular_id AND c.id = ucc.curso_id
WHERE m.status = '1'
GROUP BY e.codigo, e.nome, c.nome;
/


-- OCUPAÇÃO DE SALAS (HOJE)
CREATE OR REPLACE VIEW VW_OCUPACAO_SALAS_HOJE AS
SELECT 
    s.nome AS sala,
    TO_CHAR(a.hora_inicio, 'HH24:MI') AS inicio,
    TO_CHAR(a.hora_fim, 'HH24:MI') AS fim,
    uc.nome AS unidade_curricular,
    d.nome AS docente,
    t.nome AS turma
FROM sala s
JOIN aula a ON s.id = a.sala_id
JOIN turma t ON a.turma_id = t.id
JOIN unidade_curricular uc ON t.unidade_curricular_id = uc.id
JOIN docente d ON t.docente_id = d.id
WHERE TRUNC(a.data) = TRUNC(SYSDATE)
  AND a.status = '1';
/


--  CARGA HORÁRIA DOS DOCENTES
CREATE OR REPLACE VIEW VW_CARGA_HORARIA_DOCENTE AS
SELECT 
    d.nome AS nome_docente,
    COUNT(DISTINCT t.id) AS total_turmas,
    SUM(ROUND((a.hora_fim - a.hora_inicio) * 24, 2)) AS total_horas_semanais
FROM docente d
JOIN turma t ON d.id = t.docente_id
JOIN aula a ON t.id = a.turma_id
WHERE d.status = '1'
GROUP BY d.nome;
/


-- RELATÓRIO DE DÍVIDAS 
-- Lista alunos com pagamentos em atraso e o valor total em falta.
CREATE OR REPLACE VIEW VW_RELATORIO_DIVIDAS AS
SELECT 
    e.nome AS estudante,
    e.telemovel,
    c.nome AS curso,
    COUNT(p.id) AS parcelas_em_atraso,
    SUM(p.valor) AS valor_total_divida
FROM parcela_propina p
JOIN matricula m ON p.matricula_id = m.id
JOIN estudante e ON m.estudante_id = e.id
JOIN curso c ON m.curso_id = c.id
WHERE p.estado = '0' -- Não Pago
  AND p.data_vencimento < SYSDATE
  AND p.status = '1'
GROUP BY e.nome, e.telemovel, c.nome;
/


-- RECEITA PREVISTA VS REALIZADA POR CURSO
-- Análise financeira de desempenho por curso.
CREATE OR REPLACE VIEW VW_FINANCEIRO_CURSOS AS
SELECT 
    c.nome AS curso,
    SUM(CASE WHEN p.estado = '1' THEN p.valor ELSE 0 END) AS total_recebido,
    SUM(CASE WHEN p.estado = '0' THEN p.valor ELSE 0 END) AS total_pendente
FROM curso c
JOIN matricula m ON c.id = m.curso_id
JOIN parcela_propina p ON m.id = p.matricula_id
WHERE p.status = '1'
GROUP BY c.nome;
/


-- CALENDÁRIO DE AVALIAÇÕES
-- Para consulta dos alunos e planeamento de salas.
CREATE OR REPLACE VIEW VW_EXAMES_PROXIMOS AS
SELECT 
    av.data AS data_exame,
    uc.nome AS unidade_curricular,
    av.titulo AS avaliacao,
    ta.nome AS tipo,
    t.nome AS turma
FROM avaliacao av
JOIN turma t ON av.turma_id = t.id
JOIN unidade_curricular uc ON t.unidade_curricular_id = uc.id
JOIN tipo_avaliacao ta ON av.tipo_avaliacao_id = ta.id
WHERE av.data BETWEEN SYSDATE AND SYSDATE + 30
  AND av.status = '1'
ORDER BY av.data ASC;
/


-- MONITORIZAÇÃO DE ENTREGAS DE GRUPO
-- Cruza quem entregou trabalhos e o tamanho dos ficheiros.
CREATE OR REPLACE VIEW VW_MONITOR_ENTREGAS AS
SELECT 
    av.titulo AS avaliacao,
    en.id AS entrega_id,
    e.nome AS aluno,
    fe.nome AS ficheiro,
    ROUND(fe.tamanho / 1024, 2) AS tamanho_mb,
    en.data_entrega AS data_submissao
FROM entrega en
JOIN avaliacao av ON en.avaliacao_id = av.id
JOIN estudante_entrega ee ON en.id = ee.entrega_id
JOIN inscricao i ON ee.inscricao_id = i.id
JOIN matricula m ON i.matricula_id = m.id
JOIN estudante e ON m.estudante_id = e.id
LEFT JOIN ficheiro_entrega fe ON en.id = fe.entrega_id
WHERE en.status = '1';
/


-- ESTATÍSTICA DE OCUPAÇÃO DE CURSOS
-- Verifica a taxa de preenchimento de vagas por curso.
CREATE OR REPLACE VIEW VW_ESTATISTICA_VAGAS AS
SELECT
    c.nome AS curso,
    c.max_alunos AS vagas_totais,
    COUNT(m.id) AS alunos_matriculados,
    c.max_alunos - COUNT(m.id) AS vagas_livres,
    CASE
        WHEN c.max_alunos IS NOT NULL AND c.max_alunos > 0
        THEN ROUND((COUNT(m.id) / c.max_alunos) * 100, 2)
        ELSE "Não existe limite de alunos"
    END AS taxa_preenchimento
FROM curso c
LEFT JOIN matricula m ON c.id = m.curso_id AND m.status = '1'
WHERE c.status = '1'
GROUP BY c.nome, c.max_alunos;
/

