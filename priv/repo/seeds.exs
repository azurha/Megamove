# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Megamove.Repo.insert!(%Megamove.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Megamove.{Organizations, Places}

# Créer des organisations de test
IO.puts("🌱 Création des organisations de test...")

# Vérifier si les organisations existent déjà
existing_orgs = Organizations.list_organizations()
if length(existing_orgs) > 1 do
  IO.puts("⚠️  Des organisations existent déjà, on passe les seeds...")
  System.halt(0)
end

# Organisation expéditeur
{:ok, shipper_org} = Organizations.create_organization(%{
  name: "Transport Express SARL",
  slug: "transport-express",
  org_type: :shipper,
  address: "123 Rue de la Logistique",
  city: "Lyon",
  postal_code: "69000",
  country: "FR",
  phone: "+33 4 12 34 56 78",
  email: "contact@transport-express.fr",
  website: "https://transport-express.fr",
  vat_number: "FR12345678901",
  siret: "12345678901234"
})

# Organisation transporteur
{:ok, carrier_org} = Organizations.create_organization(%{
  name: "Fret & Co",
  slug: "fret-co",
  org_type: :carrier,
  address: "456 Avenue du Transport",
  city: "Marseille",
  postal_code: "13000",
  country: "FR",
  phone: "+33 4 91 23 45 67",
  email: "info@fret-co.fr",
  website: "https://fret-co.fr",
  vat_number: "FR98765432109",
  siret: "98765432109876"
})

# Organisation courtier
{:ok, broker_org} = Organizations.create_organization(%{
  name: "Logistics Broker Pro",
  slug: "logistics-broker-pro",
  org_type: :broker,
  address: "789 Boulevard de l'Intermodalité",
  city: "Paris",
  postal_code: "75000",
  country: "FR",
  phone: "+33 1 23 45 67 89",
  email: "contact@logistics-broker-pro.fr",
  website: "https://logistics-broker-pro.fr",
  vat_number: "FR11223344556",
  siret: "11223344556677"
})

IO.puts("✅ Organisations créées avec succès")

# Créer des lieux de test
IO.puts("🌱 Création des lieux de test...")

# Lieux pour Transport Express
{:ok, _place1} = Places.create_place(%{
  organization_id: shipper_org.id,
  name: "Entrepôt Principal Lyon",
  address: "123 Rue de la Logistique, 69000 Lyon",
  city: "Lyon",
  postal_code: "69000",
  country: "FR",
  lat: 45.764043,
  lng: 4.835659
})

{:ok, _place2} = Places.create_place(%{
  organization_id: shipper_org.id,
  name: "Dépôt Secondaire Villeurbanne",
  address: "456 Avenue de la Distribution, 69100 Villeurbanne",
  city: "Villeurbanne",
  postal_code: "69100",
  country: "FR",
  lat: 45.7666,
  lng: 4.8803
})

# Lieux pour Fret & Co
{:ok, _place3} = Places.create_place(%{
  organization_id: carrier_org.id,
  name: "Terminal Portuaire Marseille",
  address: "789 Quai de la Joliette, 13002 Marseille",
  city: "Marseille",
  postal_code: "13002",
  country: "FR",
  lat: 43.2965,
  lng: 5.3698
})

{:ok, _place4} = Places.create_place(%{
  organization_id: carrier_org.id,
  name: "Centre de Tri Aix-en-Provence",
  address: "321 Route de Nice, 13100 Aix-en-Provence",
  city: "Aix-en-Provence",
  postal_code: "13100",
  country: "FR",
  lat: 43.5263,
  lng: 5.4454
})

# Lieux pour Logistics Broker Pro
{:ok, _place5} = Places.create_place(%{
  organization_id: broker_org.id,
  name: "Bureau Principal Paris",
  address: "789 Boulevard de l'Intermodalité, 75000 Paris",
  city: "Paris",
  postal_code: "75000",
  country: "FR",
  lat: 48.8566,
  lng: 2.3522
})

IO.puts("✅ Lieux créés avec succès")

IO.puts("🎉 Seeds terminés avec succès !")
IO.puts("📊 Résumé :")
IO.puts("  - 3 organisations créées")
IO.puts("  - 5 lieux créés")
IO.puts("  - Base de données prête pour les tests")
