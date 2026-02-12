<!--
Sync Impact Report:
- Version change: [uninitialized] → 1.0.0
- Initial constitution ratification
- Principles created:
  1. Code Quality Standards
  2. Test-Driven Development (NON-NEGOTIABLE)
  3. User Experience Consistency
  4. Performance Requirements
  5. Observability & Monitoring
- Added sections:
  - Quality Gates
  - Development Workflow
- Templates status:
  ✅ .specify/templates/plan-template.md - reviewed, compatible
  ✅ .specify/templates/spec-template.md - reviewed, compatible
  ✅ .specify/templates/tasks-template.md - reviewed, compatible
- Follow-up TODOs: None
-->

# Dotfiles Constitution

## Core Principles

### I. Code Quality Standards

All code MUST adhere to the following non-negotiable quality standards:

- **Readability First**: Code is written for humans first, computers second. Use clear naming, avoid clever tricks, and prefer explicit over implicit.
- **No Code Duplication**: Extract shared logic into reusable functions or modules. The DRY principle is mandatory for logic (not just text).
- **Type Safety**: Use static typing where available. TypeScript over JavaScript, typed Python over untyped.
- **Consistent Style**: Enforce linting and formatting rules via automated tools (ESLint, Prettier, Black, etc.). Style violations block commits.
- **Documentation Required**: Every public function/module MUST have documentation explaining purpose, parameters, return values, and usage examples.
- **Security by Default**: Never introduce security vulnerabilities (XSS, SQL injection, command injection, etc.). All user input MUST be validated and sanitized.

**Rationale**: Poor code quality creates technical debt that compounds over time. Strict standards prevent degradation and ensure maintainability.

### II. Test-Driven Development (NON-NEGOTIABLE)

TDD is the mandatory development methodology:

- **Red-Green-Refactor Cycle**: (1) Write failing test → (2) User approves test → (3) Verify test fails → (4) Implement minimal code to pass → (5) Refactor if needed.
- **Test Coverage Requirements**: Minimum 80% line coverage for new code. Critical paths require 100% coverage.
- **Test Types Required**:
  - **Unit Tests**: Every function/method with non-trivial logic.
  - **Integration Tests**: Any component interaction, API contracts, database operations.
  - **End-to-End Tests**: Critical user workflows and happy paths.
- **Tests Must Be Fast**: Unit test suite MUST complete in <10 seconds. Integration tests in <60 seconds.
- **Tests Must Be Deterministic**: No flaky tests. Any test failing intermittently MUST be fixed or removed.
- **Test Isolation**: Each test MUST be independent. No shared state between tests.

**Rationale**: TDD prevents defects, enables confident refactoring, and serves as living documentation. Non-negotiable because quality without tests is unmeasurable.

### III. User Experience Consistency

User-facing features MUST provide consistent, predictable, and delightful experiences:

- **Design System Adherence**: All UI components MUST use approved design system components. No one-off custom styling without explicit approval.
- **Accessibility Standards**: WCAG 2.1 Level AA compliance is mandatory. Every interactive element MUST be keyboard navigable and screen-reader friendly.
- **Error Handling**: User-facing errors MUST be actionable. Tell users what went wrong AND how to fix it.
- **Response Time Standards**: Interactive actions MUST provide feedback within 100ms. Loading states required for operations >300ms.
- **Progressive Enhancement**: Core functionality MUST work without JavaScript. Enhanced features can require JS.
- **Mobile-First Design**: All interfaces MUST be designed for mobile first, then scaled up.
- **Consistent Terminology**: Use the same terms for the same concepts across the entire product. Maintain a glossary.

**Rationale**: Inconsistent UX creates cognitive load, reduces trust, and increases support burden. Consistency enables users to build reliable mental models.

### IV. Performance Requirements

Performance is a feature, not an afterthought:

- **Page Load Budgets**:
  - Initial load: <2s on 3G connection
  - Time to Interactive (TTI): <3.5s on mobile
  - First Contentful Paint (FCP): <1.2s
- **Bundle Size Limits**:
  - JavaScript main bundle: <200KB gzipped
  - CSS: <50KB gzipped
  - Images: WebP format preferred, max 500KB per image
- **Runtime Performance**:
  - 60 FPS for animations and scrolling
  - No operations blocking the main thread for >50ms
  - API response time: p95 <500ms, p99 <1s
- **Memory Constraints**: No memory leaks. Memory usage MUST be stable over 24-hour operation.
- **Performance Monitoring**: Core Web Vitals MUST be tracked in production. Regressions >10% trigger alerts.

**Rationale**: Performance directly impacts user satisfaction, conversion rates, and accessibility. Slow software is broken software.

### V. Observability & Monitoring

Systems MUST be observable and debuggable in production:

- **Structured Logging**: All logs MUST use structured format (JSON). Include correlation IDs, timestamps, severity levels.
- **Error Tracking**: All errors MUST be reported to error tracking system (Sentry, Rollbar, etc.) with full context.
- **Metrics Collection**: Track key business and technical metrics. SLIs MUST be defined for critical user journeys.
- **Distributed Tracing**: Multi-service requests MUST be traceable end-to-end.
- **Health Checks**: All services MUST expose health check endpoints.
- **Alerting**: Critical errors and SLO violations MUST trigger alerts within 1 minute.

**Rationale**: You cannot fix what you cannot see. Observability enables rapid incident response and data-driven optimization.

## Quality Gates

Every change MUST pass these gates before merging:

1. **Automated Tests**: All tests passing (unit, integration, e2e)
2. **Code Coverage**: Meets minimum thresholds (80% new code)
3. **Linting & Formatting**: Zero linting errors or formatting violations
4. **Type Checking**: Zero type errors
5. **Security Scanning**: Zero high/critical vulnerabilities
6. **Performance Budget**: Bundle sizes within limits, no performance regressions
7. **Accessibility Audit**: No new accessibility violations
8. **Code Review**: Approved by at least one other engineer
9. **Constitution Compliance**: Reviewer verifies adherence to all principles

**No exceptions**: Quality gates cannot be bypassed. If urgent, fix forward after merge.

## Development Workflow

### Code Review Standards

- **Review SLA**: Reviews completed within 24 hours
- **Reviewer Responsibilities**: Check for correctness, test quality, performance implications, security issues, and constitution compliance
- **Constructive Feedback**: Reviews MUST be respectful and educational
- **Small Pull Requests**: PRs SHOULD be <400 lines of code. Large PRs require justification.

### Branch Strategy

- **Main Branch**: Always deployable. Protected branch requiring PR approval.
- **Feature Branches**: Short-lived (< 1 week). Naming: `feature/description`, `fix/description`
- **Continuous Integration**: All commits trigger CI pipeline

### Deployment

- **Continuous Deployment**: Merges to main deploy automatically to staging
- **Production Deployment**: Requires explicit approval and smoke tests
- **Rollback Plan**: Every deployment MUST have documented rollback procedure

## Governance

This constitution represents the non-negotiable foundation of our engineering practices. All code, reviews, and decisions MUST comply with these principles.

### Amendment Process

1. Propose amendment with clear rationale and migration plan
2. Team discussion and consensus building
3. Documentation update
4. Version increment following semantic versioning:
   - **MAJOR**: Principle removal or backwards-incompatible changes
   - **MINOR**: New principles or sections added
   - **PATCH**: Clarifications or non-semantic refinements
5. All team members notified of changes

### Compliance

- Every pull request MUST be reviewed for constitutional compliance
- Violations MUST be addressed before merging
- Complexity that requires principle violations MUST be explicitly justified and approved
- Regular constitution review sessions (quarterly)

### Accountability

Teams and individuals are accountable for upholding these standards. Technical debt that violates principles MUST be tracked and prioritized for remediation.

**Version**: 1.0.0 | **Ratified**: 2026-02-12 | **Last Amended**: 2026-02-12
