# 🔧 Setup FatSecret API - Guia Rápido

Este guia mostra como configurar o FatSecret API para habilitar micronutrientes no FEEDLOG.

## ✅ Status: Credenciais Obtidas

Você já tem as credenciais FatSecret:
- ✅ Client ID: `ca5cfa5f1d0e45f19853641866772823`
- ✅ Client Secret: `c3b201faa34c4061bc87ac11349ce500`

---

## 📝 Próximos Passos

### 1. ✅ Configurar Whitelist de IP (JÁ FEITO)

Você já adicionou o IP na whitelist! 🎉

**⏰ Importante:** Mudanças na whitelist podem levar até **24 horas** para tomar efeito.

Se precisar verificar ou adicionar mais IPs:
- Acesse: https://platform.fatsecret.com/my-account/api-key
- Clique em "Add/edit your whitelist IP addresses here"
- Adicione: `127.0.0.1` (para desenvolvimento local)

---

### 2. ⚙️ Configurar Credenciais OpenAI

As credenciais FatSecret já estão nos scripts. Agora você só precisa adicionar suas credenciais OpenAI.

#### Passo 1: Abra o arquivo de credenciais

**Windows:** `run_with_credentials.bat`
**Linux/Mac:** `run_with_credentials.sh`

#### Passo 2: Encontre estas linhas:

```bash
# OPENAI PROXY CREDENTIALS (FILL IN YOURS!)
set OPENAI_PROXY_API_KEY=YOUR_OPENAI_PROXY_API_KEY_HERE
set OPENAI_PROXY_ENDPOINT=YOUR_OPENAI_PROXY_ENDPOINT_HERE
```

#### Passo 3: Substitua pelos seus valores:

```bash
# Exemplo:
set OPENAI_PROXY_API_KEY=sk-proj-abc123def456...
set OPENAI_PROXY_ENDPOINT=https://api.openai.com/v1
```

#### Passo 4: Salve o arquivo

---

### 3. 🚀 Executar o App

Agora você tem 2 formas de executar:

#### Opção A: Usar o script (RECOMENDADO) ⭐

**Windows:**
```bash
run_with_credentials.bat
```

**Linux/Mac:**
```bash
chmod +x run_with_credentials.sh
./run_with_credentials.sh
```

#### Opção B: Comando manual
```bash
flutter run \
  --dart-define=OPENAI_PROXY_API_KEY=seu_key \
  --dart-define=OPENAI_PROXY_ENDPOINT=seu_endpoint \
  --dart-define=FATSECRET_CLIENT_ID=ca5cfa5f1d0e45f19853641866772823 \
  --dart-define=FATSECRET_CLIENT_SECRET=c3b201faa34c4061bc87ac11349ce500
```

---

## 🧪 Como Testar

### 1. Execute o app com o script

### 2. Adicione uma refeição via chat AI

Exemplo: `café da manhã: 2 ovos, 100g de arroz, 1 copo de leite`

### 3. Verifique os logs no console

**Se funcionou (FatSecret configurado):**
```
🔄 Starting FatSecret enrichment for 1 meal(s)...
🔍 FatSecret: Searching for "ovos" (2.0g)
   ✅ Found match: "Egg, Whole" (ID: 35897)
   📊 Enriched nutrition: cal=143.0, p=12.6g, calcium=56.0mg, iron=1.8mg
```

**Se NÃO funcionou (problemas):**
```
⚠️ WARNING: FatSecret API is NOT configured!
   OU
❌ FatSecret enrichment FAILED for "ovos": OAuth token request failed: 401
```

### 4. Verifique o Dashboard

- Abra a Home page
- Role até **Micronutrientes** (parte de baixo)
- Valores devem estar **diferentes de zero:**
  - ✅ Calcium: `245 / 1000 mg`
  - ✅ Iron: `18 / 18 mg`
  - ✅ Magnesium: `42 / 400 mg`

---

## 🐛 Troubleshooting

### Erro: "FatSecret API is NOT configured"
**Causa:** Esqueceu de preencher credenciais OpenAI no script
**Solução:** Edite o script e adicione suas credenciais OpenAI

### Erro: "OAuth token request failed: 401"
**Causa:** IP não está na whitelist ou ainda não tomou efeito
**Soluções:**
1. Verifique se adicionou `127.0.0.1` na whitelist
2. Aguarde até 24 horas
3. Tente adicionar `0.0.0.0/0` (aceita qualquer IP - só para testes)

### Erro: "No results found for [alimento]"
**Causa:** Alimento não existe na base FatSecret ou nome em português
**Solução:** Tente com nomes em inglês (ex: "bread" em vez de "pão")

### Micronutrientes ainda em zero
**Causas possíveis:**
1. FatSecret não configurado (veja logs)
2. Whitelist de IP ainda não ativada (aguarde 24h)
3. Alimentos não encontrados na base
4. Dados incompletos no FatSecret (tente alimentos comuns: eggs, milk, bread)

---

## 📊 O Que Esperar

Com FatSecret funcionando, você terá dados completos para:

**Macronutrientes:**
- Calories (Calorias)
- Protein (Proteína)
- Carbohydrates (Carboidratos)
- Fat (Gordura)
- Fiber (Fibra)
- Sugar (Açúcar)
- Saturated Fat (Gordura Saturada)
- Cholesterol (Colesterol)

**Micronutrientes - Minerais:**
- Calcium (Cálcio)
- Iron (Ferro)
- Magnesium (Magnésio)
- Zinc (Zinco)
- Potassium (Potássio)
- Sodium (Sódio)

**Micronutrientes - Vitaminas:**
- Vitamin A
- Vitamin C
- Vitamin D
- Vitamin E

---

## 📝 Próximos Passos

1. ✅ Credenciais FatSecret obtidas
2. ✅ IP adicionado à whitelist
3. ⏰ Aguardar até 24h (whitelist ativar)
4. ⚙️ Adicionar credenciais OpenAI no script
5. 🚀 Executar `run_with_credentials.bat`
6. 🧪 Testar adicionando refeição
7. ✅ Verificar micronutrientes no dashboard

---

## 🔗 Links Úteis

- FatSecret API Dashboard: https://platform.fatsecret.com/my-account/api-key
- FatSecret Documentation: https://platform.fatsecret.com/api/Default.aspx
- Teste de Micronutrientes: [TEST_MICRONUTRIENTS.md](TEST_MICRONUTRIENTS.md)

---

**Dúvidas?** Verifique os logs detalhados no console - eles mostram exatamente onde está o problema! 🔍
