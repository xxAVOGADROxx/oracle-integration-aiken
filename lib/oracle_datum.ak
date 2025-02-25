use aiken/cbor
use aiken/collection/pairs

/// Represents a map of key-value pairs for price-related data
pub type PriceMap =
  Pairs<Int, Int>

/// Represents shared data that can be mixed with generic data
pub type SharedMap =
  Pairs<Int, PriceMap>

/// Represents extended data with provider-specific information
pub type ExtendedMap =
  Pairs<Int, ByteArray>

/// Represents different types of price data
pub type PriceData {
  /// Placeholder for shared data across multiple oracles
  SharedData { shared_map: SharedMap }
  /// Placeholder for extended data with additional information
  ExtendedData { extended_map: ExtendedMap }
  /// Generic data structure for price information
  GenericData { price_map: PriceMap }
}

/// Represents the main oracle datum structure
pub type OracleDatum {
  shared_data: Option<PriceData>,
  generic_data: List<PriceData>,
  extended_data: Option<PriceData>,
}

/// Retrieves the first generic data from the OracleDatum
///
/// @param oracle_datum - The OracleDatum to extract data from
/// @return The first generic data or fail if not found
pub fn get_first_generic_data(oracle_datum: OracleDatum) -> PriceData {
  when oracle_datum.generic_data is {
    [first, ..] -> first
    _ -> fail @"No generic data available"
  }
}

/// Retrieves the price from the PriceData
///
/// @param price_data - The PriceData to extract the price from
/// @return The price as an Int
pub fn get_price(price_data: PriceData) -> Int {
  when price_data is {
    GenericData { price_map } ->
      when pairs.get_first(price_map, 0) is {
        Some(price) -> price
        None -> fail @"Price not found"
      }
    _ -> fail @"Invalid PriceData variant"
  }
}

/// Retrieves the creation time from the PriceData
///
/// @param price_data - The PriceData to extract the timestamp from
/// @return The timestamp as an Int
pub fn get_created_at(price_data: PriceData) -> Int {
  when price_data is {
    GenericData { price_map } ->
      when pairs.get_first(price_map, 1) is {
        Some(timestamp) -> timestamp
        None -> fail @"Timestamp not found"
      }
    _ -> fail @"Invalid PriceData variant"
  }
}

/// Retrieves the expiry time from the PriceData
///
/// @param price_data - The PriceData to extract the expiry from
/// @return The expiry as an Int
pub fn get_expiry_at(price_data: PriceData) -> Int {
  when price_data is {
    GenericData { price_map } ->
      when pairs.get_first(price_map, 2) is {
        Some(expiry) -> expiry
        None -> fail @"Expiry not found"
      }
    _ -> fail @"Invalid PriceData variant"
  }
}

/// Retrieves the price from the OracleDatum
///
/// @param oracle_datum - The OracleDatum to extract the price from
/// @return The price as an Int
pub fn get_oracle_price(oracle_datum: OracleDatum) -> Int {
  let price_data = get_first_generic_data(oracle_datum)
  get_price(price_data)
}

/// Retrieves the creation time from the OracleDatum
///
/// @param oracle_datum - The OracleDatum to extract the timestamp from
/// @return The timestamp as an Int
pub fn get_oracle_created_at(oracle_datum: OracleDatum) -> Int {
  let price_data = get_first_generic_data(oracle_datum)
  get_created_at(price_data)
}

/// Retrieves the expiry time from the OracleDatum
///
/// @param oracle_datum - The OracleDatum to extract the timestamp from
/// @return The timestamp as an Int
pub fn get_oracle_expiry_at(oracle_datum: OracleDatum) -> Int {
  let price_data = get_first_generic_data(oracle_datum)
  get_expiry_at(price_data)
}

/// Creates a new OracleDatum with the given price, timestamp, and expiry
///
/// @param price - The price to set
/// @param timestamp - The timestamp to set
/// @param expiry - The expiry to set
/// @return A new OracleDatum
pub fn create_oracle_datum(
  price: Int,
  timestamp: Int,
  expiry: Int,
) -> OracleDatum {
  let price_map = [Pair(0, price), Pair(1, timestamp), Pair(2, expiry)]
  let price_data = GenericData { price_map }
  OracleDatum {
    shared_data: None,
    generic_data: [price_data],
    extended_data: None,
  }
}

/// Checks if the oracle data is valid (not expired)
///
/// @param oracle_datum - The OracleDatum to check
/// @param current_time - The current time to compare against
/// @return True if the oracle is valid, False otherwise
pub fn is_oracle_valid(oracle_datum: OracleDatum, current_time: Int) -> Bool {
  current_time <= get_oracle_expiry_at(oracle_datum)
}

/// Tests the OracleDatum creation and retrieval functions
test create_and_get_price() {
  let datum = create_oracle_datum(2723, 1720056807332, 1720078407332)
  get_oracle_price(datum) == 2723
}

/// Tests the OracleDatum creation and retrieval functions
test create_and_get_timestamp() {
  let datum = create_oracle_datum(2723, 1720056807332, 1720078407332)
  get_oracle_created_at(datum) == 1720056807332
}

/// Tests the OracleDatum creation and retrieval functions
test create_and_get_expiry() {
  let datum = create_oracle_datum(2723, 1720056807332, 1720078407332)
  get_oracle_expiry_at(datum) == 1720078407332
}

/// Tests if the OracleDatum is valid
test is_oracle_valid_test() {
  let datum = create_oracle_datum(2723, 1720056807332, 1720078407332)
  is_oracle_valid(datum, 1720056807332) == True && is_oracle_valid(
    datum,
    1720078407333,
  ) == False
}

/// Oracle Datum Serialisation checks
test oracle_datum_serialise() {
  let price_map =
    [Pair(0, 490850), Pair(1, 1707172554600), Pair(2, 1707176154600)]
  let price_data = GenericData { price_map }
  let datum =
    OracleDatum {
      shared_data: None,
      generic_data: [price_data],
      extended_data: None,
    }
  // The expected CBOR format based on the CDDL spec
  let expected_cbor =
    #"d8799fd87a809fd87b9fa3001a00077d62011b0000018d7b69e768021b0000018d7ba0d5e8ffffd87a80ff"

  cbor.serialise(datum) == expected_cbor
}

/// Oracle Datum Diagnostic checks
test oracle_datum_diagnostic() {
  let price_map =
    [Pair(0, 490850), Pair(1, 1707172554600), Pair(2, 1707176154600)]
  let price_data = GenericData { price_map }
  let datum =
    OracleDatum {
      shared_data: None,
      generic_data: [price_data],
      extended_data: None,
    }
  let expected_diagnostic =
    @"121([_ 122([]), [_ 123([_ {_ 0: 490850, 1: 1707172554600, 2: 1707176154600 }])], 122([])])"

  cbor.diagnostic(datum) == expected_diagnostic
}
