-- =============================================================================
-- 15. PACOTE DE BUFFER PARA VALIDAÇÃO DE INSCRIÇÕES (ANTI-MUTAÇÃO)
-- =============================================================================

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
        v_lista_inscricoes(v_lista_inscricoes.LAST).turma_id     := p_tur_id;
        v_lista_inscricoes(v_lista_inscricoes.LAST).uc_id        := p_uc_id;
        v_lista_inscricoes(v_lista_inscricoes.LAST).ects         := p_ects;
        v_lista_inscricoes(v_lista_inscricoes.LAST).ano_letivo   := p_ano;
        v_lista_inscricoes(v_lista_inscricoes.LAST).curso_id     := p_cur_id;
    END;
END PKG_BUFFER_INSCRICAO;
/
