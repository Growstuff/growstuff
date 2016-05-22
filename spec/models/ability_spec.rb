require 'rails_helper'
require 'cancan/matchers'

describe Ability do

  let(:member) { FactoryGirl.create(:member) }
  let(:ability) { Ability.new(member) }

  context "notifications" do

    it 'member can view their own notifications' do
      notification = FactoryGirl.create(:notification, recipient: member)
      ability.should be_able_to(:read, notification)
    end

    it "member can't view someone else's notifications" do
      notification = FactoryGirl.create(:notification,
        recipient: FactoryGirl.create(:member)
      )
      ability.should_not be_able_to(:read, notification)
    end
    it "member can't send messages to themself" do
      ability.should_not be_able_to(:create,
        FactoryGirl.create(:notification,
          recipient: member,
          sender: member
        )
      )
    end
    it "member can send messages to someone else" do
      ability.should be_able_to(:create,
        FactoryGirl.create(:notification,
          recipient: FactoryGirl.create(:member),
          sender: member
        )
      )
    end
  end

  context "crop wrangling" do

    let(:crop) { FactoryGirl.create(:crop) }

    context "standard member" do
      it "can't manage crops" do
        ability.should_not be_able_to(:update, crop)
        ability.should_not be_able_to(:destroy, crop)
      end

      it "can request crops" do
        ability.should be_able_to(:create, Crop)
      end

      it "can read crops" do
        ability.should be_able_to(:read, crop)
      end
    end

    context "crop wrangler" do

      let(:role) { FactoryGirl.create(:crop_wrangler) }

      before(:each) do
        member.roles << role
      end

      it "has crop_wrangler role" do
        member.has_role?(:crop_wrangler).should be true
      end

      it "can create crops" do
        ability.should be_able_to(:create, Crop)
      end
      it "can update crops" do
        ability.should be_able_to(:update, crop)
      end
      it "can destroy crops" do
        ability.should be_able_to(:destroy, crop)
      end
    end
  end

  context "products" do

    let(:product) { FactoryGirl.create(:product) }

    context "standard member" do
      it "can't read or manage products" do
        ability.should_not be_able_to(:read, product)
        ability.should_not be_able_to(:create, Product)
        ability.should_not be_able_to(:update, product)
        ability.should_not be_able_to(:destroy, product)
      end

    end

    context "admin" do

      let(:role) { FactoryGirl.create(:admin) }

      before do
        member.roles << role
      end

      it "has admin role" do
        member.has_role?(:admin).should be true
      end

      it "can read products" do
        ability.should be_able_to(:read, product)
      end
      it "can create products" do
        ability.should be_able_to(:create, Product)
      end
      it "can update products" do
        ability.should be_able_to(:update, product)
      end
      it "can destroy products" do
        ability.should be_able_to(:destroy, product)
      end
    end
  end

  context "orders" do

    let(:order) { FactoryGirl.create(:order, member: member) }
    let(:strangers_order) { FactoryGirl.create(:order,
        member: FactoryGirl.create(:member)) }
    let(:completed_order) { FactoryGirl.create(:completed_order,
        member: member) }
    let(:order_item) { FactoryGirl.create(:order_item, order: order) }
    let(:strangers_order_item) { FactoryGirl.create(:order_item,
        order: strangers_order) }
    let(:completed_order_item) { FactoryGirl.create(:order_item,
        order: completed_order) }

    context "standard member" do
      it "can read their own orders" do
        ability.should be_able_to(:read, order)
        ability.should be_able_to(:read, completed_order)
      end

      it "can't read other people's orders" do
        ability.should_not be_able_to(:read, strangers_order)
      end

      it "can create a new order" do
        ability.should be_able_to(:create, Order)
      end

      it "can complete their own current order" do
        ability.should be_able_to(:complete, order)
      end

      it "can't complete someone else's order" do
        ability.should_not be_able_to(:complete, strangers_order)
      end

      it "can't complete a completed order" do
        ability.should_not be_able_to(:complete, completed_order)
      end

      it "can delete a current order" do
        ability.should be_able_to(:destroy, order)
      end

      it "can't delete someone else's order" do
        ability.should_not be_able_to(:destroy, strangers_order)
      end

      it "can't delete a completed order" do
        ability.should_not be_able_to(:destroy, completed_order)
      end

      it "can't read their own order items" do
        ability.should_not be_able_to(:read, order_item)
        ability.should_not be_able_to(:read, completed_order_item)
      end

      it "can't read other people's order items" do
        ability.should_not be_able_to(:read, strangers_order_item)
      end

      it "can create a new order item" do
        ability.should be_able_to(:create, OrderItem)
      end

      it "can't update their own order items" do
        ability.should_not be_able_to(:update, order_item)
      end

      it "can't update other people's order items" do
        ability.should_not be_able_to(:update, strangers_order_item)
      end

      it "can't updated items in completed orders" do
        ability.should_not be_able_to(:update, completed_order_item)
      end

      it "can't delete their own order item" do
        ability.should_not be_able_to(:destroy, order_item)
      end

      it "can't delete someone else's order item" do
        ability.should_not be_able_to(:destroy, strangers_order_item)
      end

      it "can't delete items from completed orders" do
        ability.should_not be_able_to(:destroy, completed_order_item)
      end


    end

    context "admin" do

      let(:role) { FactoryGirl.create(:admin) }

      before do
        member.roles << role
      end

      it "has admin role" do
        member.has_role?(:admin).should be true
      end

      it "can read orders" do
        ability.should be_able_to(:read, order)
      end

      it "cannot create orders" do
        ability.should_not be_able_to(:create, order)
      end

      it "cannot complete orders" do
        ability.should_not be_able_to(:complete, order)
      end

      it "cannot delete orders" do
        ability.should_not be_able_to(:destroy, order)
      end

    end
  end

  context 'account details' do

    let(:account) { member.account }

    context 'ordinary member' do
      it "can't read account details" do
        ability.should_not be_able_to(:read, account)
      end
      it "can't manage account details" do
        ability.should_not be_able_to(:create, Account)
        ability.should_not be_able_to(:update, account)
        ability.should_not be_able_to(:destroy, account)
      end
    end

    context 'admin' do

      let(:role) { FactoryGirl.create(:admin) }

      before do 
        member.roles << role
      end

      it "can read account details" do
        ability.should be_able_to(:read, account)
      end
      it "can manage account details" do
        ability.should be_able_to(:create, Account)
        ability.should be_able_to(:update, account)
        ability.should be_able_to(:destroy, account)
      end

    end

  end

  context 'plant parts' do

    let(:plant_part) { FactoryGirl.create(:plant_part) }

    context 'ordinary member' do
      it "can read plant parts" do
        ability.should be_able_to(:read, plant_part)
      end
      it "can't manage plant parts" do
        ability.should_not be_able_to(:create, PlantPart)
        ability.should_not be_able_to(:update, plant_part)
        ability.should_not be_able_to(:destroy, plant_part)
      end
    end

    context 'admin' do

      let(:role) { FactoryGirl.create(:admin) }
      
      before do
        member.roles << role
      end

      it "can read plant_part details" do
        ability.should be_able_to(:read, plant_part)
      end
      it "can manage plant_part details" do
        ability.should be_able_to(:create, PlantPart)
        ability.should be_able_to(:update, plant_part)
      end

      it "can delete an unused plant part" do
        ability.should be_able_to(:destroy, plant_part)
      end

      it "can't delete a plant part that has harvests" do
        @harvest = FactoryGirl.create(:harvest, plant_part: plant_part)
        ability.should_not be_able_to(:destroy, plant_part)
      end

    end
  end

end
