-- =============================================================================
-- 4. PACOTE DE GESTÃO DE DADOS (DINÂMICO COM VERSÃO ESTÁTICA COMENTADA)
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_GESTAO_DADOS IS
    FUNCTION DEVE_FAZER_SOFT_DELETE(p_tabela IN VARCHAR2) RETURN BOOLEAN;
    PROCEDURE PRC_LOG_ALERTA(p_msg IN VARCHAR2);
    PROCEDURE PRC_LOG_ERRO(p_contexto IN VARCHAR2);
    PROCEDURE PRC_REMOVER(p_nome_tabela IN VARCHAR2, p_id_registo IN NUMBER);
END PKG_GESTAO_DADOS;
/

CREATE OR REPLACE PACKAGE BODY PKG_GESTAO_DADOS IS

    FUNCTION DEVE_FAZER_SOFT_DELETE(p_tabela IN VARCHAR2) RETURN BOOLEAN IS
        v_tab VARCHAR2(30) := UPPER(p_tabela);
    BEGIN
        IF v_tab IN ('LOG', 'ESTADO_MATRICULA') THEN RETURN FALSE; END IF;
        RETURN TRUE;
    END DEVE_FAZER_SOFT_DELETE;

    PROCEDURE PRC_LOG_ALERTA(p_msg IN VARCHAR2) IS
    BEGIN
        INSERT INTO log (id, acao, tabela, data, created_at)
        VALUES (seq_log.NEXTVAL, 'ALERTA', 'SISTEMA', p_msg, SYSDATE);
    END PRC_LOG_ALERTA;

    PROCEDURE PRC_LOG_ERRO(p_contexto IN VARCHAR2) IS
    BEGIN
        INSERT INTO log (id, acao, tabela, data, created_at)
        VALUES (seq_log.NEXTVAL, 'ERROR_TECH', UPPER(p_contexto), SUBSTR(SQLERRM, 1, 4000), SYSDATE);
    END PRC_LOG_ERRO;

    PROCEDURE PRC_REMOVER(p_nome_tabela IN VARCHAR2, p_id_registo IN NUMBER) IS
        v_sql        VARCHAR2(500);
        v_has_status NUMBER;
        v_tab        VARCHAR2(30) := UPPER(p_nome_tabela);
    BEGIN
        SELECT COUNT(*) INTO v_has_status FROM user_tab_columns 
        WHERE table_name = v_tab AND column_name = 'STATUS';

        IF v_has_status > 0 AND DEVE_FAZER_SOFT_DELETE(v_tab) THEN
            v_sql := 'UPDATE ' || v_tab || ' SET status = ''0'', updated_at = SYSDATE WHERE id = :1';
        ELSE
            v_sql := 'DELETE FROM ' || v_tab || ' WHERE id = :1';
        END IF;

        EXECUTE IMMEDIATE v_sql USING p_id_registo;

        IF SQL%ROWCOUNT = 0 THEN
            PRC_LOG_ALERTA('Remoção falhou: ID ' || p_id_registo || ' não encontrado em ' || v_tab);
        END IF;
    EXCEPTION WHEN OTHERS THEN PRC_LOG_ERRO('REMOVER_' || v_tab);
    END PRC_REMOVER;

    /* -------------------------------------------------------------------------
       VERSÃO ESTÁTICA COMPLETA (COMENTADA PARA REFERÊNCIA)
       -------------------------------------------------------------------------
    PROCEDURE PRC_REMOVER_ESTATICO(p_nome_tabela IN VARCHAR2, p_id_registo IN NUMBER) IS
        v_tab VARCHAR2(30) := UPPER(p_nome_tabela);
    BEGIN
        IF DEVE_FAZER_SOFT_DELETE(v_tab) THEN
            CASE v_tab
                WHEN 'ESTUDANTE' THEN UPDATE estudante SET status = '0', updated_at = SYSDATE WHERE id = p_id_registo;
                WHEN 'DOCENTE'   THEN UPDATE docente SET status = '0', updated_at = SYSDATE WHERE id = p_id_registo;
                WHEN 'CURSO'     THEN UPDATE curso SET status = '0', updated_at = SYSDATE WHERE id = p_id_registo;
                WHEN 'TURMA'     THEN UPDATE turma SET status = '0', updated_at = SYSDATE WHERE id = p_id_registo;
                WHEN 'MATRICULA' THEN UPDATE matricula SET status = '0', updated_at = SYSDATE WHERE id = p_id_registo;
                WHEN 'INSCRICAO' THEN UPDATE inscricao SET status = '0', updated_at = SYSDATE WHERE id = p_id_registo;
                WHEN 'AULA'      THEN UPDATE aula SET status = '0', updated_at = SYSDATE WHERE id = p_id_registo;
                WHEN 'AVALIACAO' THEN UPDATE avaliacao SET status = '0', updated_at = SYSDATE WHERE id = p_id_registo;
                WHEN 'NOTA'      THEN UPDATE nota SET status = '0', updated_at = SYSDATE WHERE inscricao_id = p_id_registo;
                -- (RESTANTES TABELAS...)
                ELSE NULL;
            END CASE;
        ELSE
            CASE v_tab
                WHEN 'LOG'              THEN DELETE FROM log WHERE id = p_id_registo;
                WHEN 'ESTADO_MATRICULA' THEN DELETE FROM estado_matricula WHERE id = p_id_registo;
                ELSE NULL;
            END CASE;
        END IF;
    END;
    */
END PKG_GESTAO_DADOS;
/
