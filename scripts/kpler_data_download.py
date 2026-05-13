from datetime import date, timedelta
from kpler.sdk import Platform
from kpler.sdk.configuration import Configuration
from kpler.sdk.resources.trades import Trades

config = Configuration(Platform.Dry, "xin.he@aramcoamericas.com", "AramcoXinhe123")

trades_client = Trades(config)

# Get US imports over last week
us_imports = trades_client.get(
    to_zones=["World"],
    products=["Iron Ore"],
    with_intra_country=True,
    start_date=date.today() - timedelta(days=7),
)

print(us_imports)