@api/v1
Feature: Account license usage report (HBAI, NICHE-427)

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin reads the usage of every license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "policy" for the second "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license" for the second "policy"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/record-usage" with the following:
      """
      { "meta": { "batchId": "batch-1", "entries": [{ "modelId": "extraction_full_premium", "day": "$date.format", "images": 3, "requests": 4, "failed": 1 }] } }
      """
    Then the response status should be "200"
    When I send a POST request to "/accounts/test1/licenses/$1/actions/record-usage" with the following:
      """
      { "meta": { "batchId": "batch-2", "entries": [{ "modelId": "extraction_full_primary", "day": "$date.format", "images": 2, "requests": 2 }] } }
      """
    Then the response status should be "200"
    When I send a GET request to "/accounts/test1/license-usage?start=$date.format&end=$date.format"
    Then the response status should be "200"
    And the response body should include the following:
      """
      { "meta": { "start": "$date.format", "end": "$date.format", "images": 5, "requests": 6, "failed": 1 } }
      """
    And the response body should contain a "data" array with 2 items
    When I send a GET request to "/accounts/test1/license-usage?start=$date.format&end=$date.format&product=$products[1]"
    Then the response status should be "200"
    And the response body should contain a "data" array with 1 items
    And the response body should include the following:
      """
      { "meta": { "start": "$date.format", "end": "$date.format", "images": 2, "requests": 2, "failed": 0 } }
      """
    When I send a DELETE request to "/accounts/test1/licenses/$0"
    Then the response status should be "204"
    When I send a GET request to "/accounts/test1/license-usage?start=$date.format&end=$date.format"
    Then the response status should be "200"
    And the response body should contain a "data" array with 2 items
    And the response body should include the following:
      """
      { "meta": { "start": "$date.format", "end": "$date.format", "images": 5, "requests": 6, "failed": 1 } }
      """

  Scenario: Admin reads usage with the end before the start
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/license-usage?start=$date.format&end=2020-01-01"
    Then the response status should be "400"

  Scenario: Admin reads usage over more than 400 days
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/license-usage?start=2020-01-01&end=2021-12-31"
    Then the response status should be "400"

  Scenario: License reads the account usage
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/license-usage?start=$date.format&end=$date.format"
    Then the response status should be "403"

  Scenario: Product reads the account usage
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/license-usage?start=$date.format&end=$date.format"
    Then the response status should be "403"

  Scenario: Admin of another account reads the usage
    Given I am an admin of account "test2"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/license-usage?start=$date.format&end=$date.format"
    Then the response status should be "401"
