-- =============================================================================
-- ALTERAÇÕES AO ESQUEMA PARA SUPORTE A MÉDIAS
-- =============================================================================

-- Adicionar nota final à inscrição (específica daquela UC naquele ano)
ALTER TABLE inscricao ADD nota_final NUMBER;

-- Adicionar média geral à matrícula (média de todas as UCs do curso)
ALTER TABLE matricula ADD media_geral NUMBER;
