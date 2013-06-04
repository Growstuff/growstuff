namespace :growstuff do

  desc "Add an admin user, by name"
  # usage: rake growstuff:admin_user name=skud

  task :admin_user => :environment do

    member = Member.find_by_login_name(ENV['name']) or raise "Usage: rake growstuff:admin_user name=whoever (login name is case-sensitive)"
    admin  = Role.find_or_create_by_name!('admin')
    member.roles << admin
  end


  namespace :oneoff do
    desc "One-off tasks needed at various times and kept for posterity"

    task :empty_subjects => :environment do
      desc "May 2013: replace any empty notification subjects with (no subject)"

      # this is inefficient as it checks every Notification, but the
      # site is small and there aren't many of them, so it shouldn't matter
      # for this one-off script.
      Notification.all.each do |n|
        n.replace_blank_subject
        n.save
      end
    end

    task :empty_garden_names => :environment do
      desc "May 2013: replace any empty garden names with Garden"

      # this is inefficient as it checks every Garden, but the
      # site is small and there aren't many of them, so it shouldn't matter
      # for this one-off script.
      Garden.all.each do |g|
        if g.name.nil? or g.name =~ /^\s*$/
          g.name = "Garden"
          g.save
        end
      end
    end


    task :setup_shop => :environment do
      puts "Adding account types..."
      AccountType.find_or_create_by_name(
        :name => "Free",
        :is_paid => false,
        :is_permanent_paid => false
      )
      @paid_account = AccountType.find_or_create_by_name(
        :name => "Paid",
        :is_paid => true,
        :is_permanent_paid => false
      )
      @seed_account = AccountType.find_or_create_by_name(
        :name => "Seed",
        :is_paid => true,
        :is_permanent_paid => true
      )
      @staff_account = AccountType.find_or_create_by_name(
        :name => "Staff",
        :is_paid => true,
        :is_permanent_paid => true
      )

      puts "Adding products..."
      Product.find_or_create_by_name(
        :name => "Annual subscription",
        :description => "An annual subscription gives you access to paid account features for one year.  Does not auto-renew.",
        :min_price => 3000,
        :account_type_id => @paid_account.id,
        :paid_months => 12
      )
      Product.find_or_create_by_name(
        :name => "Seed account",
        :description => "A seed account helps Growstuff grow in its early days.  It gives you all the features of a paid account, in perpetuity.  This account type never expires.",
        :min_price => 15000,
        :account_type_id => @seed_account.id,
      )

      puts "Giving each member an account record..."
      Member.all.each do |m|
        unless m.account
          Account.create(:member_id => m.id)
        end
      end

      puts "Making Skud a staff account..."
      @skud = Member.find_by_login_name('Skud')
      if @skud
        @skud.account.account_type = @staff_account
        @skud.account.save
      end

      puts "Done setting up shop."
    end

  end

end
