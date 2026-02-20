# Trip Planner Architecture - Step Functions Version

## Overview
This project implements a workflow-driven backend for computing trip routes and scores using AWS Step Functions.

Core Features:
- Geocoding via geopy
- Optional Google routing (feature-flagged)
- External scoring Lambda
- Phone OTP authentication (Cognito)
- Web-first, mobile-ready API design

## High-Level Flow

Client → API Gateway → StartTrip Lambda → Step Functions
    → GetFlags → Geocode → Route (Google or Basic)
    → Score → Persist → Success

## Future Enhancements
- Weather risk analysis
- Carbon footprint scoring
- Cost estimation
- ML personalization
