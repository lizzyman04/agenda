# application/shared

Cubits that belong to no single feature slice — cross-cutting app state.

## Responsibility

Holds application-wide concerns that both the tasks side and the finance
side depend on. A cubit only belongs here if moving it under `tasks/` or
`finance/` would make one feature own state the other also needs.

## Layout

```
shared/
└── locale/   the active Locale and its SharedPreferences persistence
```

`locale/` has its own README with the file/role table.

## Upstream dependencies

`core/constants/storage_keys.dart` · `shared_preferences`. No domain
dependency — nothing here knows about tasks or money.
