-- =============================================================================
-- 7. VISTAS E FUNÇÕES AUXILIARES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 7.1. FUNÇÃO: VERIFICAR SE ALUNO É DEVEDOR
-- Retorna 'S' se tiver propinas em atraso, 'N' caso contrário.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FUN_IS_DEVEDOR(p_estudante_id IN NUMBER) 
RETURN CHAR 
IS
    v_atrasos NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_atrasos 
    FROM parcela_propina p
    JOIN matricula m ON p.matricula_id = m.id
    WHERE m.estudante_id = p_estudante_id
      AND p.data_vencimento < SYSDATE
      AND p.estado != 'P'
      AND p.status = '1';

    IF v_atrasos > 0 THEN 
        RETURN 'S'; 
    END IF;
    
    RETURN 'N';
EXCEPTION 
    WHEN OTHERS THEN 
        RETURN 'N';
END;
/

-- -----------------------------------------------------------------------------
-- 7.2. VISTA: PAUTA DA TURMA (RELATÓRIO)
-- Mostra os nomes dos alunos e as suas notas finais por turma.
-- -----------------------------------------------------------------------------
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
