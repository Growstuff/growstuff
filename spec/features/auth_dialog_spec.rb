# frozen_string_literal: true

require 'rails_helper'

describe 'sign in and sign up dialogs', :js do
  let(:member) { create(:member) }

  before { visit crops_path }

  describe 'sign in' do
    before { click_link 'navbar-signin' }

    it 'opens over the page' do
      expect(page).to have_css('[role=dialog]', text: 'Sign in')
    end

    it 'stays on the page' do
      expect(page).to have_current_path crops_path
    end

    it 'closes with Escape' do
      find_by_id('sign-in-login').send_keys :escape
      expect(page).to have_no_css('[role=dialog]')
    end

    it 'signs the member in' do
      within('[role=dialog]') do
        fill_in 'Login name or email', with: member.login_name
        fill_in 'Password', with: member.password
        click_button 'Sign in'
      end
      expect(page).to have_content 'Signed in successfully'
    end

    it 'shows the error for a wrong password, and keeps the dialog open' do
      within('[role=dialog]') do
        fill_in 'Login name or email', with: member.login_name
        fill_in 'Password', with: 'wrong'
        click_button 'Sign in'
        expect(page).to have_content 'Invalid'
      end
    end
  end

  describe 'sign up' do
    before { click_link 'navbar-signup' }

    it 'opens over the page' do
      expect(page).to have_css('[role=dialog]', text: 'Join')
    end

    it 'shows the errors against their fields' do
      within('[role=dialog]') do
        fill_in 'Login name', with: 'newgrower'
        click_button 'Sign up'
        expect(page).to have_css('#sign-up-email-errors')
      end
    end

    it 'switches to sign in' do
      within('[role=dialog]') { click_link 'Sign in' }
      expect(page).to have_css('[role=dialog]', text: 'Forgot password?')
    end

    it 'joins the member' do
      within('[role=dialog]') do
        fill_in 'Login name', with: 'newgrower'
        fill_in 'Email', with: 'newgrower@example.com'
        fill_in 'Password', with: 'password1'
        fill_in 'Password confirmation', with: 'password1'
        check 'I agree to the Terms of Service'
        click_button 'Sign up'
      end
      expect(page).to have_no_css('[role=dialog]')
    end
  end
end
