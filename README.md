# ClickStack (HyperDX) — Root Helm Chart

이 저장소 루트가 Helm 차트입니다. HyperDX Helm repo의 `clickstack` 차트를 의존성으로 사용합니다.

## 빠른 시작
1) Helm repo 등록 및 의존성 받기
```
make repo
make deps
```

2) 네임스페이스/시크릿 생성
```
make ns NAMESPACE=observability
make secret NAMESPACE=observability API_KEY=<YOUR_API_KEY>
```

3) 설치/업그레이드
```
make install NAMESPACE=observability
# 또는
make upgrade NAMESPACE=observability
```

4) 상태 확인/템플릿 출력
```
make status NAMESPACE=observability
make template NAMESPACE=observability
```

5) 제거
```
make uninstall NAMESPACE=observability
```

## Kind 클러스터에서 사용하기
1) Kind 클러스터 생성(기본 이름: `clickstack`)
```
make kind-create KIND_NAME=clickstack
```

2) Kind 컨텍스트로 설치 실행
```
# kind 컨텍스트 이름은 'kind-<KIND_NAME>' 규칙을 따릅니다.
make install NAMESPACE=observability KUBE_CONTEXT=kind-clickstack
```

3) 포트(옵션)
- `kind-config.yaml`은 호스트 8080/8443 → 클러스터 80/443으로 포트 매핑합니다.
- 인그레스 컨트롤러를 설치했다면, http://localhost:8080 으로 접근할 수 있습니다.

## HTTPRoutes 사용(차트 Ingress 비활성화)
- 루트 `values.yaml`에서 `clickstack.hyperdx.ingress.enabled: false`로 비활성화합니다.
- 대신 `httpRoutes` 배열로 다수의 Gateway API `HTTPRoute`를 정의할 수 있습니다.
- 각 항목 필수값:
  - `parentRef.name` (연결할 Gateway 이름)
  - `service.name` (대상 Service 이름)
  - 선택: `hostnames`, `parentRef.namespace`, `parentRef.sectionName`, `service.port`, `pathPrefix`(기본 `/`)

예시
```
httpRoutes:
  - name: hyperdx-ui
    enabled: true
    hostnames: ["hyperdx.local"]
    parentRef:
      name: my-gateway
      namespace: default
      sectionName: http
    service:
      name: <hyperdx-ui-svc-name>
      port: 80
    pathPrefix: /

  - name: hyperdx-api
    enabled: true
    hostnames: ["api.hyperdx.local"]
    parentRef:
      name: my-gateway
    service:
      name: <hyperdx-api-svc-name>
      port: 8080
    pathPrefix: /v1
```

Service 이름 찾기 예시
```
kubectl get svc -n <namespace>
```

## 값 파일
- 기본 값: `values.yaml` (우산 차트에서 `clickstack.*`로 전달 + HTTPRoute 설정)
- Upstream 차트 직접 설치용 예시: `values-clickstack.yaml`

## 참고
- Ingress 호스트 `hyperdx.local`은 환경 도메인으로 교체하세요.
- 베타/실험 기능(`OTEL_AGENT_FEATURE_GATE_ARG`, `BETA_CH_OTEL_JSON_SCHEMA_ENABLED`)은 필요 시에만 활성화하세요.
