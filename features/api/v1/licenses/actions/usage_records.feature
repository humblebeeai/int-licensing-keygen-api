@api/v1
Feature: License usage records (HBAI, NICHE-427)

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: License records its own usage
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 1
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/record-usage" with the following:
      """
      {
        "meta": {
          "batchId": "batch-1",
          "entries": [
            { "modelId": "extraction_full_premium", "day": "$date.format", "images": 3, "requests": 4, "failed": 1 }
          ]
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 4 }
      """
    And the response body should contain meta with the following:
      """
      { "duplicate": false }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: License records the same batch twice
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 0
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/record-usage" with the following:
      """
      { "meta": { "batchId": "batch-1", "entries": [{ "modelId": "extraction_full_premium", "day": "$date.format", "images": 2, "requests": 2 }] } }
      """
    Then the response status should be "200"
    When I send a POST request to "/accounts/test1/licenses/$0/actions/record-usage" with the following:
      """
      { "meta": { "batchId": "batch-1", "entries": [{ "modelId": "extraction_full_premium", "day": "$date.format", "images": 2, "requests": 2 }] } }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 2 }
      """
    And the response body should contain meta with the following:
      """
      { "duplicate": true }
      """

  Scenario: License records usage past its limit
    Given the current account is "test1"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 5
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/record-usage" with the following:
      """
      { "meta": { "batchId": "batch-1", "entries": [{ "modelId": "extraction_full_premium", "day": "$date.format", "images": 2, "requests": 2 }] } }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 7 }
      """

  Scenario: License records usage for another license
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 2 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$1/actions/record-usage" with the following:
      """
      { "meta": { "batchId": "batch-1", "entries": [{ "modelId": "extraction_full_premium", "day": "$date.format", "images": 1, "requests": 1 }] } }
      """
    Then the response status should be "404"

  Scenario: Admin records usage for a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 0
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/record-usage" with the following:
      """
      { "meta": { "batchId": "batch-1", "entries": [{ "modelId": "extraction_full_premium", "day": "$date.format", "images": 1, "requests": 1 }] } }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 1 }
      """

  Scenario: Anonymous records usage for a license
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    When I send a POST request to "/accounts/test1/licenses/$0/actions/record-usage" with the following:
      """
      { "meta": { "batchId": "batch-1", "entries": [{ "modelId": "extraction_full_premium", "day": "$date.format", "images": 1, "requests": 1 }] } }
      """
    Then the response status should be "401"

  Scenario: License records usage for a day in the future
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/record-usage" with the following:
      """
      { "meta": { "batchId": "batch-1", "entries": [{ "modelId": "extraction_full_premium", "day": "$time.3.days.from_now.format", "images": 1, "requests": 1 }] } }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "must not be in the future",
        "source": { "pointer": "/meta/entries/0/day" }
      }
      """

  Scenario: License records usage without entries
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/record-usage" with the following:
      """
      { "meta": { "batchId": "batch-1", "entries": [] } }
      """
    Then the response status should be "400"

  Scenario: License records usage without a batch id
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/record-usage" with the following:
      """
      { "meta": { "entries": [{ "modelId": "extraction_full_premium", "day": "$date.format", "images": 1, "requests": 1 }] } }
      """
    Then the response status should be "400"

  Scenario: Admin reads the daily usage of a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]", "uses": 0 }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/record-usage" with the following:
      """
      {
        "meta": {
          "batchId": "batch-1",
          "entries": [
            { "modelId": "extraction_full_premium", "day": "$date.format", "images": 3, "requests": 4, "failed": 1 },
            { "modelId": "extraction_full_primary", "day": "$date.format", "images": 2, "requests": 2 }
          ]
        }
      }
      """
    Then the response status should be "200"
    When I send a GET request to "/accounts/test1/licenses/$0/actions/usage?start=$date.format&end=$date.format"
    Then the response status should be "200"
    And the response body should be the following:
      """
      {
        "data": [
          { "day": "$date.format", "modelId": "extraction_full_premium", "images": 3, "requests": 4, "failed": 1 },
          { "day": "$date.format", "modelId": "extraction_full_primary", "images": 2, "requests": 2, "failed": 0 }
        ],
        "meta": {
          "licenseId": "$licenses[0]",
          "start": "$date.format",
          "end": "$date.format",
          "images": 5,
          "requests": 6,
          "failed": 1
        }
      }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/actions/usage?start=$date.format&end=$date.format&model=extraction_full_primary"
    Then the response status should be "200"
    And the response body should include the following:
      """
      { "data": [{ "day": "$date.format", "modelId": "extraction_full_primary", "images": 2, "requests": 2, "failed": 0 }] }
      """

  Scenario: Admin reads the daily usage with the end before the start
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/usage?start=$date.format&end=2020-01-01"
    Then the response status should be "400"

  Scenario: License reads its own daily usage
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/actions/usage?start=$date.format&end=$date.format"
    Then the response status should be "403"
