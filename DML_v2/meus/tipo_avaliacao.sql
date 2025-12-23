-- Inserting 6 records into tipo_avaliacao
INSERT INTO tipo_avaliacao (id, nome, descricao, requer_entrega, permite_grupo, permite_filhos) VALUES (1, 'Teste', 'Avaliação individual, geralmente teórica, feita em sala.', '0', '0', '0');
INSERT INTO tipo_avaliacao (id, nome, descricao, requer_entrega, permite_grupo, permite_filhos) VALUES (2, 'Exame', 'Avaliação individual final, substitui ou complementa testes.', '0', '0', '0');
INSERT INTO tipo_avaliacao (id, nome, descricao, requer_entrega, permite_grupo, permite_filhos) VALUES (3, 'Trabalho', 'Envolve entrega (ficheiro, relatório, código, etc.), pode ser individual ou em grupo.', '1', '1', '0');
INSERT INTO tipo_avaliacao (id, nome, descricao, requer_entrega, permite_grupo, permite_filhos) VALUES (4, 'Defesa', 'Apresentação oral de um trabalho já entregue, pode ser individual ou em grupo.', '0', '1', '0');
INSERT INTO tipo_avaliacao (id, nome, descricao, requer_entrega, permite_grupo, permite_filhos) VALUES (5, 'Apresentacao', 'Exposição pública (não necessariamente defesa formal), pode complementar um trabalho.', '0', '1', '0');
INSERT INTO tipo_avaliacao (id, nome, descricao, requer_entrega, permite_grupo, permite_filhos) VALUES (6, 'Projeto', 'Variante de trabalho mais abrangente e com maior peso; pode ter defesas/apresentações associadas.', '1', '1', '1');
