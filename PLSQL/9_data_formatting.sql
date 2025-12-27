-- =============================================================================
-- 9. GATILHOS DE FORMATAÇÃO E HIGIENE DE DADOS
-- =============================================================================

CREATE OR REPLACE TRIGGER TRG_FMT_ESTUDANTE
    BEFORE INSERT OR UPDATE ON estudante FOR EACH ROW
BEGIN
    :NEW.email  := LOWER(TRIM(:NEW.email));
    :NEW.nome   := INITCAP(TRIM(:NEW.nome));
END;
/

CREATE OR REPLACE TRIGGER TRG_FMT_DOCENTE
    BEFORE INSERT OR UPDATE ON docente FOR EACH ROW
BEGIN
    :NEW.email  := LOWER(TRIM(:NEW.email));
    :NEW.nome   := INITCAP(TRIM(:NEW.nome));
END;
/

CREATE OR REPLACE TRIGGER TRG_FMT_CURSO
    BEFORE INSERT OR UPDATE ON curso FOR EACH ROW
BEGIN
    :NEW.codigo := UPPER(TRIM(:NEW.codigo));
END;
/

CREATE OR REPLACE TRIGGER TRG_FMT_UC
    BEFORE INSERT OR UPDATE ON unidade_curricular FOR EACH ROW
BEGIN
    :NEW.codigo := UPPER(TRIM(:NEW.codigo));
END;
/

CREATE OR REPLACE TRIGGER TRG_FMT_MATRICULA
    BEFORE INSERT OR UPDATE ON matricula FOR EACH ROW
BEGIN
    :NEW.estado_matricula := INITCAP(TRIM(:NEW.estado_matricula));
END;
/