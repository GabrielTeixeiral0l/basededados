-- -----------------------------------------------------------------------------
-- 7.1. VISTAS (Reporting)
-- -----------------------------------------------------------------------------

-- Vista de Ficha de Aluno Completa
CREATE OR REPLACE VIEW VW_FICHA_ALUNO AS
SELECT 
    e.id, e.nome, e.email, e.telemovel,
    m.ano_inscricao, c.nome as curso,
    (SELECT COUNT(*) FROM inscricao i WHERE i.matricula_id = m.id) as total_ucs_inscritas
FROM estudante e
JOIN matricula m ON e.id = m.estudante_id
JOIN curso c ON m.curso_id = c.id
WHERE e.status = '1' AND m.status = '1';

-- Vista de Alunos com Propinas em Atraso
CREATE OR REPLACE VIEW VW_DEVEDORES AS
SELECT 
    e.nome, e.email, pp.valor, pp.data_vencimento,
    TRUNC(SYSDATE - pp.data_vencimento) as dias_atraso
FROM estudante e
JOIN matricula m ON e.id = m.estudante_id
JOIN parcela_propina pp ON m.id = pp.matricula_id
WHERE pp.estado = 'N' AND pp.data_vencimento < SYSDATE;

-- -----------------------------------------------------------------------------
-- 7.2. FUNÇÕES
-- -----------------------------------------------------------------------------

-- Média Atual do Aluno (ponderada por ECTS se possível, aqui simples por nota)
CREATE OR REPLACE FUNCTION FUN_GET_MEDIA_ALUNO(p_estudante_id IN NUMBER) 
RETURN NUMBER IS
    v_media NUMBER;
BEGIN
    SELECT AVG(n.nota)
    INTO v_media
    FROM nota n
    JOIN inscricao i ON n.inscricao_id = i.id
    JOIN matricula m ON i.matricula_id = m.id
    WHERE m.estudante_id = p_estudante_id;
    
    RETURN NVL(v_media, 0);
END;
/

-- Verifica se o Aluno é Devedor
CREATE OR REPLACE FUNCTION FUN_IS_DEVEDOR(p_estudante_id IN NUMBER) 
RETURN CHAR IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM parcela_propina pp
    JOIN matricula m ON pp.matricula_id = m.id
    WHERE m.estudante_id = p_estudante_id
      AND pp.estado = 'N'
      AND pp.data_vencimento < SYSDATE;
      
    IF v_count > 0 THEN RETURN 'S'; ELSE RETURN 'N'; END IF;
END;
/
