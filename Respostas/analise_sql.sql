-- 1. Quantos chamados foram abertos no dia 01/04/2023?
SELECT COUNT(*) AS chamados
FROM `datario.adm_central_atendimento_1746.chamado`
WHERE TIMESTAMP_TRUNC(data_inicio, DAY) = '2023-04-01';
-- Resposta: 1756 chamados foram abertos.

-- 2. Qual o tipo de chamado que teve mais teve chamados abertos no dia 01/04/2023?
SELECT tipo, COUNT(*) AS chamadas_por_tipo 
FROM `datario.adm_central_atendimento_1746.chamado`
WHERE DATE(data_inicio) = '2023-04-01'
GROUP BY tipo
ORDER BY chamadas_por_tipo DESC
-- Resposta: Estacionamento irregular 366 chamados.

-- 3. Quais os nomes dos 3 bairros que mais tiveram chamados abertos nesse dia?
SELECT b.nome AS bairro, COUNT(c.id_bairro) AS total_chamados-- Usei c para chamado e b para bairro para tornar a query mais curta.
FROM `datario.adm_central_atendimento_1746.chamado` c
JOIN `datario.dados_mestres.bairro` b
ON c.id_bairro = b.id_bairro
WHERE c.data_particao = "2023-04-01"
GROUP BY b.nome
ORDER BY total_chamados DESC
-- Resposta: 1-Campo Grande ,2-Tijuca e 3-Barra da Tijuca.

-- 4.Qual o nome da subprefeitura com mais chamados abertos nesse dia?
SELECT 
  b.subprefeitura,
  COUNT(c.id_bairro) AS qtd_chamado 
FROM 
  `datario.adm_central_atendimento_1746.chamado` c
RIGHT JOIN 
  `datario.dados_mestres.bairro` b
  ON c.id_bairro = b.id_bairro
WHERE
  DATE(c.data_inicio) = '2023-04-01'
GROUP BY
  b.subprefeitura
ORDER BY
  qtd_chamado DESC;
-- Resposta: Zona Norte com 510 chamados abertos.

-- 5.Existe algum chamado aberto nesse dia que não foi associado a um bairro ou subprefeitura na tabela de bairros? Se sim, por que isso acontece?
SELECT 
  b.nome AS nome_bairro,
  b.subprefeitura,
  COUNT(*) AS qtd_chamado 
FROM 
  `datario.adm_central_atendimento_1746.chamado` c
LEFT JOIN 
  `datario.dados_mestres.bairro` b
  ON c.id_bairro = b.id_bairro
WHERE
  DATE(c.data_inicio) = '2023-04-01'
GROUP BY
  b.nome, b.subprefeitura
ORDER BY
  qtd_chamado DESC;
-- Resposta: Sim foram 73 chamados. As razões podem ser: chamados genéricos sem associação a um bairro específico, problemas de qualidade de dados como registros incorretos ou ausentes e erros ou atrasos na sincronização de dados entre sistemas.

-- 6.Quantos chamados com o subtipo "Perturbação do sossego" foram abertos desde 01/01/2022 até 31/12/2023 (incluindo extremidades)?
SELECT 
  subtipo, COUNT(*) AS chamados_por_subtipo
FROM 
  `datario.adm_central_atendimento_1746.chamado`
WHERE 
  data_inicio BETWEEN '2022-01-01' AND '2023-12-31' 
  AND subtipo = 'Perturbação do sossego'
GROUP BY 
  subtipo;
-- Resposta:  42.830 chamados abertos.

-- 7.Selecione os chamados com esse subtipo que foram abertos durante os eventos contidos na tabela de eventos (Reveillon, Carnaval e Rock in Rio).
-- Usei c para a tabela chamado e r para a tabela rede_hoteleira_ocupacao_eventos para tornar o código mais curto e legível.
SELECT r.evento
FROM `datario.adm_central_atendimento_1746.chamado` c
RIGHT JOIN `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` r
ON c.data_inicio BETWEEN r.data_inicial AND r.data_final
WHERE c.subtipo = 'Perturbação do sossego';
-- Resposta: Continua

-- 8. Quantos chamados desse subtipo foram abertos em cada evento?
SELECT 
  e.evento,
  COUNT(*) AS chamados_por_evento
FROM 
  `datario.adm_central_atendimento_1746.chamado` AS c
RIGHT JOIN 
  `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` AS e
ON 
  DATE(c.data_inicio) BETWEEN DATE(e.data_inicial) AND DATE(e.data_final)
WHERE 
  c.subtipo = 'Perturbação do sossego'
GROUP BY 
  e.evento
-- Resposta: 834 chamados no Rock in Rio
-- 			 241 chamados no Carnaval 
--           139 chamados no Reveillon

-- 9. Qual evento teve a maior média diária de chamados abertos desse subtipo?

WITH diarias AS (
  SELECT
    e.evento,
    DATE(c.data_inicio) AS data_chamado,
    COUNT(*) AS chamados_diarios
  FROM
    `datario.adm_central_atendimento_1746.chamado` AS c
  RIGHT JOIN
    `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` AS e
    ON DATE(c.data_inicio) BETWEEN DATE(e.data_inicial) AND DATE(e.data_final)
  WHERE
    c.subtipo = 'Perturbação do sossego'
  GROUP BY
    e.evento,
    DATE(c.data_inicio)
)
SELECT
  evento,
  AVG(chamados_diarios) AS media_chamados_por_evento
FROM
  diarias
GROUP BY
  evento
-- Resposta: Rock in Rio. A CTE diarias conta chamados diários por evento, e a consulta principal calcula a média diária desses chamados por evento.

-- 10. Compare as médias diárias de chamados abertos desse subtipo durante os eventos específicos (Reveillon, Carnaval e Rock in Rio) e a média diária de chamados abertos desse subtipo considerando todo o período de 01/01/2022 até 31/12/2023.
WITH diarias AS (
  -- Contagem de chamados por dia durante os períodos dos eventos
  SELECT
    e.evento,
    DATE(c.data_inicio) AS data_chamado,
    COUNT(*) AS chamados_diarios
  FROM
    `datario.adm_central_atendimento_1746.chamado` AS c
  RIGHT JOIN
    `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` AS e
    ON DATE(c.data_inicio) BETWEEN DATE(e.data_inicial) AND DATE(e.data_final)
  WHERE
    c.subtipo = 'Perturbação do sossego'
  GROUP BY
    e.evento,
    DATE(c.data_inicio)
),
media_chamados_por_evento AS (
  -- Calcula a média de chamados diários por evento
  SELECT
    evento,
    AVG(chamados_diarios) AS media_chamados_por_evento
  FROM
    diarias
  GROUP BY
    evento
),
media_chamados_ano AS (
  -- Calcula a média de chamados diários no período total
  SELECT
    AVG(chamados_diarios) AS media_diaria_chamados
  FROM (
    SELECT
      DATE(data_inicio) AS data_chamada,
      COUNT(*) AS chamados_diarios
    FROM
      `datario.adm_central_atendimento_1746.chamado`
    WHERE
      DATE(data_inicio) BETWEEN '2022-01-01' AND '2023-12-31'
      AND subtipo = 'Perturbação do sossego'
    GROUP BY
      DATE(data_inicio)
  ) AS diarios
)
-- Seleção dos dados comparando a média dos eventos com a média anual
SELECT
  m.evento,
  m.media_chamados_por_evento,
  a.media_diaria_chamados
FROM
  media_chamados_por_evento AS m
JOIN
  media_chamados_ano AS a
ON
  TRUE

-- Resposta: 
-- Rock in Rio:
-- Média de chamados por evento: 119,14
-- Média diária de chamados: 61,98
-- Análise: O Rock in Rio tem uma média diária de chamados significativamente superior à média geral, indicando que o número de chamados durante esse evento foi bem mais alto do que a média diária no período total.

-- Reveillon:
-- Média de chamados por evento: 46,33
-- Média diária de chamados: 61,98
-- Análise: O Reveillon tem uma média diária de chamados inferior à média geral, sugerindo que o volume de chamados durante o evento foi menor do que o volume médio diário no período total.

-- Carnaval:
-- Média de chamados por evento: 60,25
-- Média diária de chamados: 61,98
-- nálise: O Carnaval tem uma média diária de chamados próxima à média geral, com uma ligeira redução, indicando que o volume de chamados durante o evento foi apenas um pouco menor do que a média diária no período total.
-- Resumo: O Rock in Rio apresenta uma média de chamados bem acima da média geral de chamados de 'Pertubação do sossego', enquanto o Reveillon está abaixo e o Carnaval é bastante próximo da média geral, mas ligeiramente abaixo. Isso reflete diferentes padrões de volume de chamados associados a cada evento em comparação com o período de dois anos.