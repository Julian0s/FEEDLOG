# 🧪 Teste de Micronutrientes - FatSecret API

Este documento explica como testar se os micronutrientes estão sendo populados corretamente.

## 📋 Pré-requisitos

1. **Credenciais FatSecret API**
   - Client ID
   - Client Secret
   - Obtenha em: https://platform.fatsecret.com/api/

2. **Credenciais OpenAI Proxy**
   - API Key
   - Endpoint URL

3. **⚠️ IMPORTANTE: Whitelist de IP do FatSecret**
   - Acesse: https://platform.fatsecret.com/my-account/api-key
   - Clique em "Add/edit your whitelist IP addresses here"
   - Adicione pelo menos um IP:
     - `127.0.0.1` (localhost)
     - `0.0.0.0/0` (qualquer IP - apenas para testes)
     - Ou seu IP público (obtenha em https://www.whatismyip.com/)
   - **⏰ Mudanças podem levar até 24 horas para tomar efeito**

## 🚀 Como Executar o Teste

### Opção A: Usar script de credenciais (RECOMENDADO) ⭐

1. **Edite o arquivo de credenciais:**
   - Windows: Abra `run_with_credentials.bat` em um editor de texto
   - Linux/Mac: Abra `run_with_credentials.sh` em um editor de texto

2. **Preencha suas credenciais OpenAI:**
   ```bash
   # Substitua estas linhas com seus dados reais:
   set OPENAI_PROXY_API_KEY=seu_openai_key_aqui
   set OPENAI_PROXY_ENDPOINT=seu_openai_endpoint_aqui
   ```

3. **Execute o script:**
   - Windows: Dê duplo clique em `run_with_credentials.bat`
   - Linux/Mac: `chmod +x run_with_credentials.sh && ./run_with_credentials.sh`

### Opção B: Comando manual

```bash
flutter run \
  --dart-define=OPENAI_PROXY_API_KEY=seu_openai_key \
  --dart-define=OPENAI_PROXY_ENDPOINT=seu_openai_endpoint \
  --dart-define=FATSECRET_CLIENT_ID=seu_fatsecret_client_id \
  --dart-define=FATSECRET_CLIENT_SECRET=seu_fatsecret_client_secret
```

### 2. Abra o app e faça login

### 3. Adicione uma refeição via AI Chat

Exemplos de input:
- Português: `café da manhã: 40g de torrada com manteiga e 1 xícara de café`
- Inglês: `breakfast: 2 eggs, 100g rice, 1 glass of milk`
- Espanhol: `desayuno: 2 huevos, 100g de arroz, 1 vaso de leche`

### 4. Monitore os logs no console

Você verá saídas detalhadas como:

```
⚠️ WARNING: FatSecret API is NOT configured!        <-- Se não configurou
   OU
🔄 Starting FatSecret enrichment for 1 meal(s)...   <-- Se configurou

📝 Processing Breakfast with 3 food item(s)
   BEFORE enrichment: torrada - calcium=0.0mg, iron=0.0mg
🔍 FatSecret: Searching for "torrada" (40.0g)
   ✅ Found match: "Toast" (ID: 12345)
   📊 Enriched nutrition: cal=106.0, p=3.6g, calcium=45.2mg, iron=1.3mg
   AFTER enrichment: torrada - calcium=45.2mg, iron=1.3mg

   ✅ Meal totals: calcium=245.5mg, iron=3.8mg, vitA=125.0, vitC=2.5mg
```

### 5. Verifique o Dashboard

- Abra a Home page
- Role até a seção de **Micronutrientes** (parte de baixo)
- Verifique se os valores estão **DIFERENTES de zero**:
  - ❌ ERRADO: `0 / 1000 mg` (todos em zero)
  - ✅ CORRETO: `245 / 1000 mg`, `18 / 18 mg`, etc.

## 🔍 Cenários de Teste

### ✅ Teste 1: FatSecret CONFIGURADO
**Esperado:**
- Console mostra: `🔍 FatSecret: Searching for...`
- Console mostra: `📊 Enriched nutrition: ... calcium=XX.Xmg`
- Dashboard mostra micronutrientes **preenchidos**

### ❌ Teste 2: FatSecret NÃO CONFIGURADO
**Esperado:**
- Console mostra: `⚠️ WARNING: FatSecret API is NOT configured!`
- SnackBar laranja aparece: `⚠️ Micronutrients unavailable: FatSecret API not configured`
- Dashboard mostra micronutrientes em **zero**

### ⚠️ Teste 3: FatSecret com erro (credenciais inválidas)
**Esperado:**
- Console mostra: `❌ FatSecret enrichment FAILED for "...": ...`
- Dashboard mostra micronutrientes em **zero** (fallback para estimativas locais)

## 📊 Micronutrientes que devem ser populados

Se FatSecret estiver funcionando, você verá valores para:

**Minerais:**
- Calcium (Cálcio)
- Iron (Ferro)
- Magnesium (Magnésio)
- Zinc (Zinco)
- Potassium (Potássio)
- Sodium (Sódio)

**Vitaminas:**
- Vitamin A
- Vitamin C
- Vitamin D
- Vitamin E

## 🐛 Troubleshooting

### Problema: Micronutrientes em zero mesmo com FatSecret configurado

**Possíveis causas:**

1. **Credenciais inválidas**
   - Verifique se Client ID e Secret estão corretos
   - Console mostrará erro de OAuth

2. **Alimento não encontrado na base FatSecret**
   - Console mostrará: `❌ No results found for "..."`
   - Tente com alimentos em inglês (ex: "bread" em vez de "pão")

3. **Resposta da API sem micronutrientes**
   - Alguns alimentos na base FatSecret têm dados incompletos
   - Tente alimentos comuns (eggs, milk, bread, rice)

4. **Rate limit excedido**
   - FatSecret tem limite de requests
   - Aguarde alguns minutos e tente novamente

### Problema: Erro "OAuth token request failed"

**Possíveis causas:**
1. **Credenciais inválidas**
   - Verifique se Client ID e Secret estão corretos
   - Verifique se a conta FatSecret está ativa
   - Tente gerar novas credenciais no painel FatSecret

2. **IP não está na whitelist** ⚠️ **MAIS COMUM**
   - Acesse: https://platform.fatsecret.com/my-account/api-key
   - Verifique se adicionou `127.0.0.1` ou seu IP na whitelist
   - Aguarde até 24 horas para mudanças tomarem efeito
   - Console mostrará: `FatSecretError: OAuth token request failed: 401`

## 📝 Exemplo de Log Completo (Sucesso)

```
⚠️ WARNING: FatSecret API is NOT configured!   <-- OU mensagem de sucesso
🔄 Starting FatSecret enrichment for 1 meal(s)...

📝 Processing Breakfast with 3 food item(s)
   BEFORE enrichment: torrada - calcium=0.0mg, iron=0.0mg
🔍 FatSecret: Searching for "torrada" (40.0g)
   ✅ Found match: "Toast, Plain" (ID: 35674)
   📊 Enriched nutrition: cal=106.0, p=3.6g, calcium=45.2mg, iron=1.3mg
   AFTER enrichment: torrada - calcium=45.2mg, iron=1.3mg

   BEFORE enrichment: manteiga - calcium=0.0mg, iron=0.0mg
🔍 FatSecret: Searching for "manteiga" (7.0g)
   ✅ Found match: "Butter, Salted" (ID: 3145)
   📊 Enriched nutrition: cal=50.2, p=0.1g, calcium=1.7mg, iron=0.0mg
   AFTER enrichment: manteiga - calcium=1.7mg, iron=0.0mg

   BEFORE enrichment: café preto - calcium=0.0mg, iron=0.0mg
🔍 FatSecret: Searching for "café preto" (240.0ml)
   ✅ Found match: "Coffee, Black" (ID: 8901)
   📊 Enriched nutrition: cal=2.4, p=0.3g, calcium=4.8mg, iron=0.0mg
   AFTER enrichment: café preto - calcium=4.8mg, iron=0.0mg

   ✅ Meal totals: calcium=51.7mg, iron=1.3mg, vitA=35.2, vitC=0.0mg

✅ Enrichment complete!
```

## ✅ Checklist Final

- [ ] App rodando com todas as 4 variáveis de ambiente (OpenAI + FatSecret)
- [ ] Console NÃO mostra warning "FatSecret NOT CONFIGURED"
- [ ] Console mostra "🔍 FatSecret: Searching for..."
- [ ] Console mostra "📊 Enriched nutrition: ... calcium=XX.Xmg"
- [ ] Dashboard mostra micronutrientes DIFERENTES de zero
- [ ] Valores fazem sentido (ex: 1 ovo tem ~50mg calcium)

Se TODOS os itens estiverem marcados, a integração está funcionando! ✅
