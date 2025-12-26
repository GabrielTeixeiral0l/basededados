-- =============================================================================
-- 7. VISTAS E FUNÇÕES AUXILIARES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 7.1. FUNÇÃO: VERIFICAR SE ALUNO É DEVEDOR
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

    IF v_atrasos > 0 THEN RETURN 'S'; END IF;
    RETURN 'N';
EXCEPTION WHEN OTHERS THEN RETURN 'N';
END;
/

-- -----------------------------------------------------------------------------
-- 7.2. VISTA: PAUTA DA TURMA
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

-- -----------------------------------------------------------------------------
-- 7.3. VISTA: ALERTAS DE ASSIDUIDADE (> 25% de faltas)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_ALERTA_ASSIDUIDADE AS
SELECT 
    e.nome as NOME_ESTUDANTE,
    t.nome as NOME_TURMA,
    COUNT(CASE WHEN p.presente = '0' THEN 1 END) as TOTAL_FALTAS,
    COUNT(*) as TOTAL_AULAS,
    ROUND((COUNT(CASE WHEN p.presente = '0' THEN 1 END) / COUNT(*)) * 100, 2) as PERC_FALTAS
FROM presenca p
JOIN inscricao i ON p.inscricao_id = i.id
JOIN matricula m ON i.matricula_id = m.id
JOIN estudante e ON m.estudante_id = e.id
JOIN turma t ON i.turma_id = t.id
WHERE i.status = '1' AND p.status = '1'
GROUP BY e.nome, t.nome
HAVING (COUNT(CASE WHEN p.presente = '0' THEN 1 END) / COUNT(*)) > 0.25;
/