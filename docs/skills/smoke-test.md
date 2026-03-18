# Smoke Test — deep doc

This document describes the `smoke-test` Skill: a focused set of checks for validating essential functionality after changes.

Design
------
- Keep tests small and fast (ideally < 1 minute).
- Use least-privileged credentials and avoid destructive operations.

Typical checks
--------------
- Instance reachability (TCP/ICMP/TLS handshake)
- Basic API call with limited scope (e.g., list compartments)
- Health endpoints for services

CI integration
--------------
- Run smoke-tests post-apply during deployment pipelines.
