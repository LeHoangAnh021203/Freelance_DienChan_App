# Protocols API

## `GET /api/v1/protocols`

Danh sách phác đồ.

## `GET /api/v1/protocols/{id}`

Chi tiết phác đồ và các bước thực hành.

## Response Fields

- `id`
- `name`
- `conditionIds`
- `recommendedTime`
- `durationMinutes`
- `warningLevel`
- `steps`

## Step Fields

- `order`
- `acupointId`
- `guide`
- `durationSeconds`
