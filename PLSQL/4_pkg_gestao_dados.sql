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
        PKG_LOG.ERRO('Falha ao remover relacao em ' || v_tab || ': ' || SQLERRM, v_tab);
    END PRC_REMOVER_RELACAO;

END PKG_GESTAO_DADOS;
/