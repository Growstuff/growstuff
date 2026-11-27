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

    it 'provides the form without a page layout for the dialog' do
      get new_domesticated_animal_path, params: { dialog: 'true' }
      expect(Capybara.string(response.body)).to have_css('form#new_domesticated_animal input[name="dialog"][value="true"]', visible: :all)
    end

    it 'keeps validation errors in the dialog form' do
      post domesticated_animals_path, params: { dialog: 'true', domesticated_animal: attributes.merge(name: '') }
      expect(Capybara.string(response.body)).to have_css('form#new_domesticated_animal .invalid-feedback')
    end

    it 'creates an animal owned by the signed-in member' do
      post domesticated_animals_path, params: { domesticated_animal: attributes.merge(owner_id: create(:member).id) }
      expect(member.domesticated_animals.pluck(:name)).to eq ['Henrietta']
    end

    it 'shows the animal' do
      get domesticated_animal_path(animal)
      expect(response).to have_http_status(:ok)
    end

    it 'shows an empty jobs section without related jobs' do
      get domesticated_animal_path(animal)
      expect(Capybara.string(response.body)).to have_css('#jobs p.text-muted')
    end

    context 'with jobs linked to the animal' do
      let(:job) { create(:job, owner: member, jobbable: animal, name: 'Feed Henrietta') }

      it 'shows the related job' do
        job
        get domesticated_animal_path(animal)
        expect(Capybara.string(response.body)).to have_css('#jobs .job', text: job.name)
      end

      it 'includes completed jobs' do
        job.update!(finished: true)
        get domesticated_animal_path(animal)
        expect(Capybara.string(response.body)).to have_css('#jobs .card-finished', text: job.name)
      end

      it 'excludes jobs for other animals' do
        other_animal = create(:domesticated_animal, owner: member)
        other_job = create(:job, owner: member, jobbable: other_animal, name: 'Walk Fido')
        get domesticated_animal_path(animal)
        expect(Capybara.string(response.body)).to have_no_css('#jobs .job', text: other_job.name)
      end

      it 'excludes unlinked jobs' do
        other_job = create(:job, owner: member, name: 'Water the garden')
        get domesticated_animal_path(animal)
        expect(Capybara.string(response.body)).to have_no_css('#jobs .job', text: other_job.name)
      end

      it 'offers a job form linked to the animal' do
        get domesticated_animal_path(animal)
        expect(Capybara.string(response.body)).to have_link(
          href: new_job_path(jobbable_type: 'DomesticatedAnimal', jobbable_id: animal.id)
        )
      end

      it 'orders dated jobs before undated jobs' do
        job.update!(due_date: nil)
        earlier_job = create(:job, owner: member, jobbable: animal, name: 'Check water', due_date: Date.new(2026, 1, 1))
        get domesticated_animal_path(animal)
        expect(Capybara.string(response.body).all('#jobs .job h4').map(&:text)).to eq [earlier_job.name, job.name]
      end
    end

    it 'shows the edit form' do
      get edit_domesticated_animal_path(animal)
      expect(response).to have_http_status(:ok)
    end

    it 'updates the animal' do
      patch domesticated_animal_path(animal), params: { domesticated_animal: { name: 'Henny' } }
      expect(animal.reload.name).to eq 'Henny'
    end

    it 'saves an alignment when creating an animal' do
      post domesticated_animals_path, params: { domesticated_animal: attributes.merge(alignment: 'chaotic_good') }
      expect(member.domesticated_animals.last.alignment).to eq 'chaotic_good'
    end

    it 'updates the alignment' do
      patch domesticated_animal_path(animal), params: { domesticated_animal: { alignment: 'lawful_evil' } }
      expect(animal.reload.alignment).to eq 'lawful_evil'
    end

    it 'clears an alignment' do
      animal.update!(alignment: 'chaotic_evil')
      patch domesticated_animal_path(animal), params: { domesticated_animal: { alignment: '' } }
      expect(animal.reload.alignment).to be_nil
    end

    it 'shows the saved alignment' do
      animal.update!(alignment: 'true_neutral')
      get domesticated_animal_path(animal)
      expect(Capybara.string(response.body)).to have_css('dd', text: I18n.t('domesticated_animals.alignments.true_neutral'))
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

    it 'shows related jobs to visitors' do
      job = create(:job, owner: member, jobbable: animal)
      get domesticated_animal_path(animal)
      expect(Capybara.string(response.body)).to have_css('#jobs .job', text: job.name)
    end

    it 'does not offer visitors the add job link' do
      get domesticated_animal_path(animal)
      expect(Capybara.string(response.body)).to have_no_link(
        href: new_job_path(jobbable_type: 'DomesticatedAnimal', jobbable_id: animal.id)
      )
    end
  end
end
