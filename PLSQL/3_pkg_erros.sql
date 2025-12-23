CREATE OR REPLACE PACKAGE PKG_ERROS IS
    -- Definição de constantes para códigos de erro
    ERR_TURMA_CHEIA_CODE CONSTANT NUMBER := -20001;
    ERR_ALUNO_DIVIDA_CODE CONSTANT NUMBER := -20002;
    ERR_NOTA_INVALIDA_CODE CONSTANT NUMBER := -20003;
    ERR_CONFLITO_HORA_CODE CONSTANT NUMBER := -20004;
    ERR_NAO_ENCONTRADO_CODE CONSTANT NUMBER := -20005;
    ERR_DATA_ENTREGA_CODE CONSTANT NUMBER := -20006;

    -- Procedimento para disparar exceções padronizadas
    PROCEDURE RAISE_ERROR(p_codigo IN NUMBER);
END PKG_ERROS;
/

CREATE OR REPLACE PACKAGE BODY PKG_ERROS IS
    PROCEDURE RAISE_ERROR(p_codigo IN NUMBER) IS
    BEGIN
        CASE p_codigo
            WHEN ERR_TURMA_CHEIA_CODE THEN
                RAISE_APPLICATION_ERROR(ERR_TURMA_CHEIA_CODE, 'Lotação da sala excedida para esta turma.');
            WHEN ERR_ALUNO_DIVIDA_CODE THEN
                RAISE_APPLICATION_ERROR(ERR_ALUNO_DIVIDA_CODE, 'Operação impedida: Aluno possui dívidas pendentes.');
            WHEN ERR_NOTA_INVALIDA_CODE THEN
                RAISE_APPLICATION_ERROR(ERR_NOTA_INVALIDA_CODE, 'A nota inserida deve estar entre 0 e 20.');
            WHEN ERR_CONFLITO_HORA_CODE THEN
                RAISE_APPLICATION_ERROR(ERR_CONFLITO_HORA_CODE, 'Conflito de horário detetado para a sala ou docente.');
            WHEN ERR_NAO_ENCONTRADO_CODE THEN
                RAISE_APPLICATION_ERROR(ERR_NAO_ENCONTRADO_CODE, 'O registo solicitado não existe ou está inativo.');
            WHEN ERR_DATA_ENTREGA_CODE THEN
                RAISE_APPLICATION_ERROR(ERR_DATA_ENTREGA_CODE, 'A data de entrega não pode ser inferior à data da avaliação.');
            ELSE
                RAISE_APPLICATION_ERROR(-20999, 'Erro genérico de regra de negócio.');
        END CASE;
    END RAISE_ERROR;
END PKG_ERROS;
/
