const speciesByCategory = {
  dog: 'Canis lupus familiaris',
  cat: 'Felis catus',
  chicken: 'Gallus gallus domesticus',
  turkey: 'Meleagris gallopavo',
  duck: 'Anas platyrhynchos domesticus',
  goose: 'Anser anser domesticus',
  guinea_pig: 'Cavia porcellus',
  sheep: 'Ovis aries',
  horse: 'Equus caballus',
  goat: 'Capra hircus',
  pig: 'Sus scrofa domesticus',
  rabbit: 'Oryctolagus cuniculus domesticus',
  donkey: 'Equus asinus',
  alpaca: 'Vicugna pacos',
  llama: 'Lama glama',
  quail: 'Coturnix japonica',
  guinea_fowl: 'Numida meleagris',
  pigeon: 'Columba livia domestica',
  ferret: 'Mustela putorius furo',
};

export function initDomesticatedAnimals(root = document) {
  const categories = root.querySelectorAll('input[name="domesticated_animal[category]"]');
  const species = root.querySelector('#domesticated_animal_species');
  if (!categories.length || !species) return;

  const selected = Array.from(categories).find((category) => category.checked);
  let previousDefault = speciesByCategory[selected?.value] || '';
  categories.forEach((category) => {
    category.addEventListener('change', () => {
      if (!category.checked) return;
      const nextDefault = speciesByCategory[category.value] || '';
      // Keep a member's own species name, including when editing an animal.
      if (!species.value.trim() || species.value === previousDefault) {
        species.value = nextDefault;
        species.dispatchEvent(new Event('input', {bubbles: true}));
      }
      previousDefault = nextDefault;
    });
  });
}

document.addEventListener('DOMContentLoaded', () => initDomesticatedAnimals());
