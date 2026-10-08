# V-Architect

A voice-first floor plan creation web app designed to help people with motor
disabilities create floor plans without relying on a mouse or precise touch input.

**Live demo:** https://j1nsakai.github.io/fyp/

## Problem
Most floor plan tools depend on precise pointer input (dragging, resizing,
snapping), which is difficult for users with motor impairments. V-Architect
explores voice as the primary input method.

## How it works
The user speaks commands such as [2-3 real example commands from your app].
Speech is converted to text using [speech-to-text package/API you used], and the
text is matched against a **predefined command grammar** that maps phrases to
floor plan actions (e.g. add a room, place a door).

The system does **not** use natural language understanding or machine learning
to interpret intent. Commands must follow the supported phrasing.

## Limitations
- Only supported command phrasings are recognized; free-form speech is not
- background noise
- No tested with real people having motor-disabilities

## Possible future work
- Replace the fixed command grammar with a language-understanding component
  and compare it against the command-based approach.


## Tech stack
Flutter (Web), Speech-to-Text package

## Team and contribution
Built as a Final Year Project by three students at Isra University, Hyderabad
(2024).
|Contributor|Role|Contribution|
|------|-----|-------|
|Taimoor|Web Development|Built the Controller, Model and Service layer of the application|
|Ishwar Lal Khatri|Ideation and Web Development|Built the Views layer of the application, and the ideation for the project|
|Sajan|Presentation and Thesis|Worked on the presentation of the project and made the Thesis drafts|
