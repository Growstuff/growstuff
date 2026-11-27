import {beforeEach, describe, expect, it} from 'vitest';
import {initDomesticatedAnimals} from './domesticated_animals';

describe('initDomesticatedAnimals', () => {
  let species;

  const selectCategory = (value) => {
    const category = document.querySelector(`input[value="${value}"]`);
    category.checked = true;
    category.dispatchEvent(new Event('change', {bubbles: true}));
  };

  beforeEach(() => {
    document.body.innerHTML = `
      ${[
        'dog', 'cat', 'chicken', 'turkey', 'duck', 'goose', 'guinea_pig', 'sheep', 'horse', 'goat', 'pig',
        'rabbit', 'donkey', 'alpaca', 'llama', 'quail', 'guinea_fowl', 'pigeon', 'ferret', 'other',
      ].map((category) => `
        <input type="radio" name="domesticated_animal[category]" value="${category}">
      `).join('')}
      <input id="domesticated_animal_species">`;
    species = document.getElementById('domesticated_animal_species');
  });

  describe('when selecting a category', () => {
    beforeEach(() => initDomesticatedAnimals());

    it.each([
      ['dog', 'Canis lupus familiaris'],
      ['cat', 'Felis catus'],
      ['chicken', 'Gallus gallus domesticus'],
      ['turkey', 'Meleagris gallopavo'],
      ['duck', 'Anas platyrhynchos domesticus'],
      ['goose', 'Anser anser domesticus'],
      ['guinea_pig', 'Cavia porcellus'],
      ['sheep', 'Ovis aries'],
      ['horse', 'Equus caballus'],
      ['goat', 'Capra hircus'],
      ['pig', 'Sus scrofa domesticus'],
      ['rabbit', 'Oryctolagus cuniculus domesticus'],
      ['donkey', 'Equus asinus'],
      ['alpaca', 'Vicugna pacos'],
      ['llama', 'Lama glama'],
      ['quail', 'Coturnix japonica'],
      ['guinea_fowl', 'Numida meleagris'],
      ['pigeon', 'Columba livia domestica'],
      ['ferret', 'Mustela putorius furo'],
      ['other', ''],
    ])('prefills the scientific name for %s', (value, scientificName) => {
      selectCategory(value);
      expect(species.value).toBe(scientificName);
    });

    it('updates a previous suggestion', () => {
      selectCategory('dog');
      selectCategory('cat');
      expect(species.value).toBe('Felis catus');
    });

    it('clears the suggested species when choosing other', () => {
      selectCategory('sheep');
      selectCategory('other');
      expect(species.value).toBe('');
    });

    it('preserves a custom species when choosing other', () => {
      species.value = 'Lama glama';
      selectCategory('other');
      expect(species.value).toBe('Lama glama');
    });

    it('preserves a custom species', () => {
      selectCategory('turkey');
      species.value = 'Meleagris ocellata';
      selectCategory('chicken');
      expect(species.value).toBe('Meleagris ocellata');
    });

    it('fills a species that has been cleared', () => {
      selectCategory('cat');
      species.value = '';
      selectCategory('dog');
      expect(species.value).toBe('Canis lupus familiaris');
    });
  });

  describe('when editing an animal', () => {
    beforeEach(() => {
      document.querySelector('input[value="turkey"]').checked = true;
      species.value = 'Meleagris ocellata';
      initDomesticatedAnimals();
    });

    it('leaves the saved species unchanged on load', () => {
      expect(species.value).toBe('Meleagris ocellata');
    });

    it('preserves the saved custom species after changing category', () => {
      selectCategory('chicken');
      expect(species.value).toBe('Meleagris ocellata');
    });
  });

  describe('without an animal form', () => {
    it('does not require the form fields', () => {
      document.body.innerHTML = '';
      expect(() => initDomesticatedAnimals()).not.toThrow();
    });
  });
});
