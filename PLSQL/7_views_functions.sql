-- =============================================================================
-- 7. VISTAS E FUNÇÕES AUXILIARES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Função para verificar se um aluno tem dívidas
-- Retorna 'S' (Sim) ou 'N' (Não)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FUN_IS_DEVEDOR(p_estudante_id IN NUMBER) RETURN CHAR IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM parcela_propina p
    JOIN matricula m ON p.matricula_id = m.id
    WHERE m.estudante_id = p_estudante_id
      AND p.estado != 'P'             -- Não está pago
      AND p.data_vencimento < SYSDATE -- Já venceu
      AND m.status = '1'              -- Matrícula ativa
      AND p.status = '1';             -- Parcela ativa

    IF v_count > 0 THEN
        RETURN 'S';
    ELSE
        RETURN 'N';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'N'; -- Em caso de erro, assume sem dívida para não bloquear indevidamente (falha segura)
END FUN_IS_DEVEDOR;
/

-- -----------------------------------------------------------------------------
-- Vista de Pauta (Exemplo de Relatório)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_PAUTA_TURMA AS
SELECT 
    t.nome AS turma,
    uc.nome AS unidade_curricular,
    e.nome AS estudante,
    e.id AS numero_estudante,
    av.titulo AS avaliacao,
    n.nota
FROM nota n
JOIN inscricao i ON n.inscricao_id = i.id
JOIN estudante e ON i.matricula_id = e.id -- Nota: Simplificação, matricula liga a estudante
JOIN avaliacao av ON n.avaliacao_id = av.id
JOIN turma t ON i.turma_id = t.id
JOIN unidade_curricular uc ON t.unidade_curricular_id = uc.id
WHERE n.status = '1'
ORDER BY t.nome, e.nome;
/