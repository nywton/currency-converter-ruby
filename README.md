# Desafio Técnico - Ruby on Rails + Vue.js (Opcional)

## 💸 Desafio: Conversor de Moedas

Você deverá implementar uma aplicação que permita a conversão de valores entre moedas, utilizando **Ruby on Rails** como backend e **Vue.js** como frontend (opcional).

> **Importante:** Caso o candidato não possua familiaridade com Vue.js, a entrega pode ser feita exclusivamente com Rails e APIs RESTful.

---

## 📆 Requisitos do Projeto

### Funcionalidades principais

1. A API deve permitir a conversão entre pelo menos **4 moedas**:

   * BRL (Real)
   * USD (Dólar Americano)
   * EUR (Euro)
   * JPY (Iene)

2. As **taxas de câmbio** devem ser obtidas da API:

   * [https://app.currencyapi.com/](https://app.currencyapi.com/)
   * Documentação oficial: [https://currencyapi.com/docs](https://currencyapi.com/docs)
   * A API gratuita requer autenticação com chave e retorna taxas baseadas na moeda desejada.

3. A aplicação deve **persistir** cada transação realizada, contendo:

   * ID do usuário
   * Moeda de origem e destino
   * Valor de origem
   * Valor convertido (destino)
   * Taxa de conversão
   * Data/Hora UTC

4. As transações devem estar disponíveis via endpoint:

   * `GET /transactions?user_id=123`

5. Uma transação de sucesso deve retornar:

   ```json
   {
     "transaction_id": 42,
     "user_id": 123,
     "from_currency": "USD",
     "to_currency": "BRL",
     "from_value": 100,
     "to_value": 525.32,
     "rate": 5.2532,
     "timestamp": "2024-05-19T18:00:00Z"
   }
   ```

6. Casos de falha devem retornar **status HTTP adequado** e mensagem de erro clara.

7. O projeto deve conter **testes unitários e de integração**.

8. O repositório deve incluir um **README.md** com:

   * Instruções para rodar o projeto
   * Explicação do propósito
   * Principais decisões de arquitetura
   * Como os dados estão organizados (separação de camadas)

9. O código deve estar todo em **inglês**.

10. O projeto deve ser entregue via repositório no GitHub.

---

## 🔜 Itens Desejáveis

* Logs
* Tratamento de exceções personalizado
* Documentação da API (Swagger, Rswag, Postman, etc.)
* Coesão de commits e mensagens descritivas
* Configuração de **linters** (Rubocop, ESLint, etc.)
* Deploy funcional (Heroku, Fly.io, etc.)
* Integração contínua (CI/CD com GitHub Actions ou similar)
* Testes de ponta a ponta se usar Vue.js (Cypress, Playwright)

---

## 🚀 Stack Tecnológica Esperada

### Backend:

* Ruby on Rails 7+
* PostgreSQL ou SQLite
* Faraday ou HTTParty para chamadas externas
* RSpec para testes

### Frontend (opcional):

* Vue.js 3 + TypeScript
* Axios
* Pinia ou Vuex (opcional)
* TailwindCSS (opcional)

---

## 💡 Diferenciais para o Perfil da Vaga

* Familiaridade com **AWS** (EC2, RDS, S3)
* Capacidade de discutir arquitetura e otimização de custos
* Experiência com **CI/CD**
* Excelente comunicação em inglês
* Proatividade e interesse em produto
* Participação em decisões técnicas com o time de produto e dados

---

## 📋 Entrega

1. Faça um fork deste repositório ou crie um novo projeto em seu GitHub
2. Crie uma branch com seu nome em snake\_case (ex: `joao_silva_souza`)
3. Suba seu código com commits organizados
4. Abra um Pull Request com:

   * Título: `Entrega - joao_silva_souza`
   * Corpo: nome completo, data da entrega e observações (se necessário)

---

## 📢 Contato e Observações

* Caso utilize algum recurso pago (ex: API, hospedagem), informe alternativas gratuitas no README.
* Encorajamos entregas que demonstrem pensamento crítico sobre performance, qualidade de código e arquitetura.
* Se tiver sugestões ou dúvidas, registre no README como "Considerações finais".

Boa sorte! 🚀
