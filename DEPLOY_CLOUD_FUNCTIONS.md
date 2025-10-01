# 🚀 Deploy Cloud Functions - Guia Completo

Este guia mostra como fazer deploy das Cloud Functions do FEEDLOG para permitir publicação segura na App Store e Play Store.

## 📋 O Que São Cloud Functions?

Cloud Functions são um backend serverless que:
- ✅ **Mantém credenciais seguras** (FatSecret/OpenAI ficam no servidor)
- ✅ **Permite publicar o app** sem expor API keys
- ✅ **Escala automaticamente** conforme uso
- ✅ **Integra nativamente** com Firebase

---

## 🏗️ Arquitetura

**Antes (Desenvolvimento):**
```
Flutter App → FatSecret API (credenciais no app ❌)
Flutter App → OpenAI API (credenciais no app ❌)
```

**Depois (Produção):**
```
Flutter App → Firebase Functions → FatSecret/OpenAI ✅
(sem credenciais)     (credenciais seguras)
```

---

## 📦 Arquivos Criados

### Backend (Firebase Functions):
```
functions/
├── package.json              # Dependências Node.js
├── index.js                  # Endpoints principais
├── .env.example              # Template de credenciais
├── .gitignore               # Protege .env
└── src/
    ├── fatsecret.js         # Integração FatSecret
    └── openai.js            # Integração OpenAI
```

### Frontend (Flutter):
```
lib/
├── services/
│   └── cloud_functions_service.dart    # Cliente para chamar Functions
└── core/widgets/
    └── global_chat_fab_cloud.dart      # Chat UI atualizado
```

### Config:
```
firebase.json                 # Config do Functions
pubspec.yaml                 # Adicionado cloud_functions: ^4.0.0
```

---

## 🔧 Setup Local (Desenvolvimento)

### 1. Instalar dependências do Functions

```bash
cd functions
npm install
```

### 2. Configurar credenciais locais

```bash
# Copiar template
cp .env.example .env

# Editar .env com suas credenciais
```

Edite `functions/.env`:
```bash
FATSECRET_CLIENT_ID=ca5cfa5f1d0e45f19853641866772823
FATSECRET_CLIENT_SECRET=c3b201faa34c4061bc87ac11349ce500
OPENAI_PROXY_API_KEY=seu_openai_key_aqui
OPENAI_PROXY_ENDPOINT=seu_openai_endpoint_aqui
```

### 3. Testar localmente com emulator

```bash
# Terminal 1: Rodar emulador Firebase
firebase emulators:start --only functions

# Terminal 2: Rodar app Flutter
flutter run
```

O app vai chamar Functions locais automaticamente!

---

## 🌐 Deploy para Produção

### 1. Configurar credenciais no Firebase (Secrets)

**Opção A: Usar Firebase CLI (RECOMENDADO)**

```bash
# Configurar secrets
firebase functions:secrets:set FATSECRET_CLIENT_ID
# Cole: ca5cfa5f1d0e45f19853641866772823

firebase functions:secrets:set FATSECRET_CLIENT_SECRET
# Cole: c3b201faa34c4061bc87ac11349ce500

firebase functions:secrets:set OPENAI_PROXY_API_KEY
# Cole: seu_key

firebase functions:secrets:set OPENAI_PROXY_ENDPOINT
# Cole: seu_endpoint
```

**Opção B: Usar Firebase Console**
1. Acesse: https://console.firebase.google.com/project/feedlog-a4bec/functions
2. Clique em "Secrets" → "Add Secret"
3. Adicione cada credencial

### 2. Atualizar index.js para usar secrets

```javascript
// Substituir estas linhas em functions/index.js:
const fatSecret = new FatSecretClient(
  process.env.FATSECRET_CLIENT_ID,
  process.env.FATSECRET_CLIENT_SECRET
);

// POR:
const fatSecret = new FatSecretClient(
  functions.config().fatsecret.client_id,
  functions.config().fatsecret.client_secret
);
```

### 3. Fazer deploy

```bash
# Deploy apenas Functions
firebase deploy --only functions

# Ou deploy completo (Functions + Firestore rules)
firebase deploy
```

### 4. Verificar deploy

```bash
# Ver logs
firebase functions:log

# Testar endpoint
firebase functions:shell
> parseMeal({userText: "2 ovos"})
```

---

## 📱 Atualizar App Flutter para Produção

### 1. Trocar para versão Cloud

Em `lib/core/router/app_router.dart` (ou onde usa GlobalChatFAB):

```dart
// ANTES (desenvolvimento):
import '../widgets/global_chat_fab.dart';

// DEPOIS (produção):
import '../widgets/global_chat_fab_cloud.dart';
```

### 2. Remover dependências antigas (opcional)

Agora você pode remover:
- `lib/openai/openai_config.dart`
- `lib/fatsecret/fatsecret_config.dart`
- `lib/fatsecret/fatsecret_helper.dart`

Mas mantenha para compatibilidade se quiser usar ambos.

### 3. Build de produção

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# NÃO precisa mais de --dart-define! 🎉
```

---

## 💰 Custos Estimados

### Firebase Blaze Plan (Pay as you go):

**Cloud Functions:**
- 2M invocations/mês: **Grátis**
- Depois: ~$0.40 por 1M invocations
- GB-s compute: $0.0000025/GB-s
- GB-s memory: $0.0000025/GB-s

**Estimativa para FEEDLOG:**
- ~1000 usuários ativos/mês
- ~10 refeições/usuário/mês
- = 10.000 invocations/mês
- **Custo: $0 (dentro do free tier)**

**Se crescer muito:**
- 100.000 invocations/mês: ~$3-5/mês
- 1.000.000 invocations/mês: ~$20-40/mês

---

## 🧪 Como Testar

### Teste Local (Emulator):

1. `firebase emulators:start --only functions`
2. `flutter run`
3. Adicionar refeição via chat
4. Ver logs no terminal do emulator

### Teste Produção:

1. `firebase deploy --only functions`
2. `flutter run --release`
3. Adicionar refeição via chat
4. Ver logs: `firebase functions:log`

---

## 🐛 Troubleshooting

### Erro: "Function not found"
**Causa:** Deploy incompleto ou nome errado
**Solução:** `firebase deploy --only functions` e verificar nome em `index.js`

### Erro: "unauthenticated"
**Causa:** Usuário não logado no Firebase Auth
**Solução:** Fazer login no app antes de usar chat

### Erro: "Missing environment variables"
**Causa:** Secrets não configurados
**Solução:** Configurar secrets com `firebase functions:secrets:set`

### Functions lentas (cold start)
**Causa:** Primeira invocação após inatividade
**Solução:**
- Normal (5-10 segundos)
- Usar Cloud Run para sempre-ativo (custo extra)
- Configurar min instances (Blaze plan)

### Erro: "CORS blocked"
**Causa:** Chamada de domínio não autorizado
**Solução:** Adicionar CORS em `index.js`:
```javascript
const cors = require('cors')({origin: true});
exports.myFunction = functions.https.onRequest((req, res) => {
  cors(req, res, () => {
    // função aqui
  });
});
```

---

## 📊 Endpoints Disponíveis

### 1. `parseMeal`
**Entrada:** `{ userText: string }`
**Saída:** `{ meals: [...], dailyTotals: {...} }`
**Uso:** Parsear texto para estrutura de refeição

### 2. `enrichFood`
**Entrada:** `{ name: string, quantity: number, unit: string }`
**Saída:** `{ name, quantity, unit, estimates: {...} }`
**Uso:** Enriquecer 1 alimento com FatSecret

### 3. `parseMealWithEnrichment` ⭐ **RECOMENDADO**
**Entrada:** `{ userText: string }`
**Saída:** `{ meals: [...] }` (já enriquecidos)
**Uso:** Combina parseMeal + enrichFood em 1 chamada

### 4. `analyzeNutritionLabel`
**Entrada:** `{ imageBase64: string }`
**Saída:** `{ serving_size, nutrients: {...} }`
**Uso:** OCR de rótulo nutricional

---

## ✅ Checklist de Deploy

- [ ] `npm install` em `functions/`
- [ ] Configurar `.env` local para testes
- [ ] Testar com emulator: `firebase emulators:start`
- [ ] Configurar secrets no Firebase
- [ ] `firebase deploy --only functions`
- [ ] Atualizar app para usar `global_chat_fab_cloud.dart`
- [ ] `flutter pub get` (adiciona cloud_functions package)
- [ ] Build de produção SEM `--dart-define`
- [ ] Testar deploy em produção
- [ ] Verificar logs: `firebase functions:log`

---

## 🔗 Links Úteis

- Firebase Console: https://console.firebase.google.com/project/feedlog-a4bec
- Functions Dashboard: https://console.firebase.google.com/project/feedlog-a4bec/functions
- Firebase CLI Docs: https://firebase.google.com/docs/cli
- Cloud Functions Docs: https://firebase.google.com/docs/functions

---

**Pronto para produção!** 🎉

Agora você pode publicar o FEEDLOG nas lojas sem expor credenciais.
