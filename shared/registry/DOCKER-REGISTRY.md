# DOCKER REGISTRY

> Wspólny rejestr kontenerów Docker dla całej infrastruktury
> Aktualizują: Claude Code [CC], Clawdbot [CB]

---

## Aktywne kontenery

| Nazwa | Obraz | Port | Sieć | Status | Instalator | Data |
|-------|-------|------|------|--------|------------|------|
| - | - | - | - | - | - | - |

---

## AI/ML Kontenery (z CUDA)

| Nazwa | Obraz | CUDA | cuDNN | PyTorch | Driver | VRAM | Status |
|-------|-------|------|-------|---------|--------|------|--------|
| - | - | - | - | - | - | - | - |

---

## Sieci Docker

| Sieć | Zakres IP | Przeznaczenie |
|------|-----------|---------------|
| traefik-public | 172.20.0.0/16 | Usługi publiczne |
| internal | 172.21.0.0/16 | Komunikacja wewnętrzna |
| monitoring | 172.22.0.0/16 | Stack monitoringu |
| database | 172.23.0.0/16 | Izolacja baz danych |
| clawdbot | 172.25.0.0/16 | Sieć Clawdbot |

---

## Historia zmian

<!-- Format: [DATA] [SOURCE] kontener | akcja -->
