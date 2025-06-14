# Домашнее задание 1 «Финансовый Укротитель»

**Дата выдачи:** 14 июня 2025  
**Максимальный балл:** 3

## Описание проекта

Приложение учёта расходов и доходов на SwiftUI. В первой домашке реализована только бизнес-логика без интерфейса «Анализ».

### Что должно работать

1. **Доменные модели**  
   - `Category` (с полями `id`, `name`, `emoji`, `isIncome`; вычисляемое свойство `direction: Direction`)  
   - `BankAccount` (с полями `id`, `userId?`, `name`, `balance: Decimal`, `currency`, `createdAt?`, `updatedAt?`)  
   - `Transaction` (с полями `id`, `account`, `category`, `amount: Decimal`, `transactionDate: Date`, `comment?`, `createdAt`, `updatedAt`)

2. **JSON-сериализация**  
   - Расширение `Transaction` с методом  
     ```swift
     static func parse(jsonObject: Any) -> Transaction?
     ```  
     для десериализации из Foundation-объектов.  
   - Вычислимым свойством  
     ```swift
     var jsonObject: Any
     ```  
     которое возвращает Foundation-объект (словарь) для `JSONSerialization`.

3. **Кеширование**  
   - Класс `TransactionsFileCache` с методами:  
     - `add(_:)`, `remove(id:)`  
     - `saveAll()` и `loadAll()` (работа с любым файлом JSON, защита от дублирования по `id`).

4. **Моки сервисов**  
   - `CategoriesService` (методы `categories()` и `categories(direction:)`)  
   - `BankAccountsService` (методы `getAccount()` и `updateAccount(_:)`)  
   - `TransactionsService` (`getTransactions(from:to:)`, `createTransaction(_:)`, `updateTransaction(_:)`, `deleteTransaction(id:)`)

5. **Задание со звездочкой**  
   - Разбор CSV-строки в `Transaction.fromCSV(_:)` и генерация CSV-линии через `toCSV`.

6. **Задание с двумя звездочками**  
   - Unit-тесты для `parse(jsonObject:)` и `jsonObject` в модуле `FinanceAppTests`.

## Запуск и проверка

1. Откройте `FinanceApp.xcodeproj` или `FinanceApp.xcworkspace`.  
2. Соберите схему `FinanceApp`.  
3. Запустите тесты схемы `FinanceAppTests` (⌘U) — все должны пройти зелёным.

---

**Критерии оценки**  
- **3 балла** — выполнено всё ТЗ и оба «звёздочных» задания.  
- **2 балла** — выполнено всё ТЗ и одно «звёздочное» задание.  
- **1 балл** — выполнено только основное ТЗ.  
- **0 баллов** — ничего не выполнено.  
