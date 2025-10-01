# FEEDLOG Cloud Functions

Firebase Cloud Functions para integração segura com APIs externas (FatSecret e OpenAI).

## 🎯 Propósito

Manter credenciais de API seguras no backend, permitindo publicação do app nas lojas sem expor API keys.

## 📁 Estrutura

```
functions/
├── package.json         # Dependências Node.js
├── index.js            # Endpoints HTTP/Callable
├── .env.example        # Template de credenciais
├── .env                # Credenciais locais (NÃO comitar!)
└── src/
    ├── fatsecret.js    # Cliente FatSecret API
    └── openai.js       # Cliente OpenAI API
```

## 🚀 Setup Rápido

### 1. Instalar dependências
```bash
npm install
```

### 2. Configurar credenciais locais
```bash
cp .env.example .env
# Editar .env com suas credenciais
```

### 3. Testar localmente
```bash
firebase emulators:start --only functions
```

### 4. Deploy para produção
```bash
# Configurar secrets
firebase functions:secrets:set FATSECRET_CLIENT_ID
firebase functions:secrets:set FATSECRET_CLIENT_SECRET
firebase functions:secrets:set OPENAI_PROXY_API_KEY
firebase functions:secrets:set OPENAI_PROXY_ENDPOINT

# Deploy
firebase deploy --only functions
```

## 📡 Endpoints

### `parseMealWithEnrichment` (Recomendado)
Parseia texto e enriquece com FatSecret em uma chamada.

**Input:**
```json
{ "userText": "2 ovos, 100g arroz, 1 copo de leite" }
```

**Output:**
```json
{
  "meals": [
    {
      "mealType": "snack",
      "foods": [...],
      "totals": { "calories": 450, "calcium": 250, ... }
    }
  ]
}
```

### `parseMeal`
Apenas parseia texto (sem enriquecimento).

### `enrichFood`
Enriquece um alimento individual com FatSecret.

### `analyzeNutritionLabel`
OCR de rótulo nutricional via OpenAI Vision.

## 🔒 Segurança

- ✅ Requer autenticação Firebase Auth
- ✅ Credenciais nunca expostas ao cliente
- ✅ Rate limiting por usuário (TODO)
- ✅ Validação de input

## 📊 Custos

Firebase Blaze Plan (pay-as-you-go):
- **2M invocations/mês: GRÁTIS**
- Estimativa FEEDLOG: ~10k invocations/mês = **$0**

## 📖 Documentação Completa

Ver [DEPLOY_CLOUD_FUNCTIONS.md](../DEPLOY_CLOUD_FUNCTIONS.md) para guia detalhado de deploy.
