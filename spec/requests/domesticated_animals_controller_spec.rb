# frozen_string_literal: true

require 'rails_helper'

describe DomesticatedAnimalsController do
  let(:member) { create(:member) }
  let(:animal) { create(:domesticated_animal, owner: member) }
  let(:attributes) { { name: 'Henrietta', species: 'Gallus gallus domesticus', category: 'chicken' } }

  context 'when the feature is disabled' do
    before { sign_in member }

    it 'does not show animal pages' do
      get domesticated_animal_path(animal)
      expect(response).to have_http_status(:not_found)
    end

    it 'does not create animals' do
      expect { post domesticated_animals_path, params: { domesticated_animal: attributes } }.not_to change(DomesticatedAnimal, :count)
    end

    it 'does not show animals on profiles' do
      animal
      get member_path(member)
      expect(response.body).not_to include domesticated_animal_path(animal)
    end

    it 'does not offer animals in job suggestions' do
      animal
      get job_suggestions_path, params: { q: 'Henri' }
      expect(response.parsed_body).to be_empty
    end

    it 'does not accept an animal link for a job' do
      expect do
        post jobs_path, params: { job: { name: 'Feed', jobbable_type: 'DomesticatedAnimal', jobbable_id: animal.id } }
      end.not_to change(Job, :count)
    end

    it 'does not open the animal photo picker' do
      get new_photo_path(format: :json), params: { type: 'domesticated_animal', id: animal.id }
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when enabled for a member' do
    before do
      Feature.find(:domesticated_animals).enable_member(member)
      sign_in member
    end

    it 'shows the creation form' do
      get new_domesticated_animal_path
      expect(response).to have_http_status(:ok)
    end

    it 'creates an animal owned by the signed-in member' do
      post domesticated_animals_path, params: { domesticated_animal: attributes.merge(owner_id: create(:member).id) }
      expect(member.domesticated_animals.pluck(:name)).to eq ['Henrietta']
    end

    it 'shows the animal' do
      get domesticated_animal_path(animal)
      expect(response).to have_http_status(:ok)
    end

    it 'shows the edit form' do
      get edit_domesticated_animal_path(animal)
      expect(response).to have_http_status(:ok)
    end

    it 'updates the animal' do
      patch domesticated_animal_path(animal), params: { domesticated_animal: { name: 'Henny' } }
      expect(animal.reload.name).to eq 'Henny'
    end

    it 'renders validation errors' do
      post domesticated_animals_path, params: { domesticated_animal: attributes.merge(name: '') }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'deletes the animal' do
      delete domesticated_animal_path(animal)
      expect(DomesticatedAnimal.find_by(id: animal.id)).to be_nil
    end

    it 'shows animals on the member profile' do
      animal
      get member_path(member)
      expect(response.body).to include domesticated_animal_path(animal)
    end

    it 'offers only owned animals in post suggestions' do
      animal
      create(:domesticated_animal)
      get link_suggestions_posts_path(format: :json), params: { term: 'Henri' }
      expect(response.parsed_body['animals'].pluck('id')).to eq [animal.id]
    end

    it 'offers animals in job suggestions' do
      animal
      get job_suggestions_path, params: { q: 'Henri' }
      expect(response.parsed_body.pluck('jobbable_type')).to eq ['DomesticatedAnimal']
    end

    it 'creates a job linked to the animal' do
      post jobs_path, params: { job: { name: 'Feed Henrietta', jobbable_type: 'DomesticatedAnimal', jobbable_id: animal.id } }
      expect(member.jobs.last.jobbable).to eq animal
    end

    it 'keeps the animal link on the new job form' do
      get new_job_path(jobbable_type: 'DomesticatedAnimal', jobbable_id: animal.id)
      expect(Capybara.string(response.body)).to have_css('input[name="job[jobbable_id]"][type="hidden"]', visible: :all)
    end

    it 'renders animal links in post previews' do
      post preview_posts_path, params: { body: "Meet [Henrietta](animal:#{animal.id})" }, as: :json
      expect(response.body).to include domesticated_animal_path(animal)
    end

    it 'opens the animal photo picker' do
      get new_photo_path(format: :json), params: { type: 'domesticated_animal', id: animal.id }
      expect(response).to have_http_status(:ok)
    end

    it 'shows the animal on its photo page' do
      photo = create(:photo, owner: member)
      animal.photos << photo
      get photo_path(photo)
      expect(response.body).to include domesticated_animal_path(animal)
    end

    context 'with another member\'s animal' do
      let(:animal) { create(:domesticated_animal) }

      it 'does not allow editing' do
        patch domesticated_animal_path(animal), params: { domesticated_animal: { name: 'Stolen' } }
        expect(animal.reload.name).to eq 'Henrietta'
      end

      it 'does not allow deletion' do
        delete domesticated_animal_path(animal)
        expect(DomesticatedAnimal.find_by(id: animal.id)).to eq animal
      end

      it 'does not allow linking jobs' do
        expect do
          post jobs_path, params: { job: { name: 'Feed', jobbable_type: 'DomesticatedAnimal', jobbable_id: animal.id } }
        end.not_to change(Job, :count)
      end

      it 'does not open the photo picker' do
        get new_photo_path(format: :json), params: { type: 'domesticated_animal', id: animal.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context 'when enabled globally', flipper: :domesticated_animals do
    it 'shows animals to visitors' do
      get domesticated_animal_path(animal)
      expect(response).to have_http_status(:ok)
    end
  end
end
