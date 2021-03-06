require 'spec_helper_acceptance'

describe 'mysql::db define' do
  describe 'creating a database' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      pp = <<-EOS
        class { 'mysql::server': root_password => 'password' }
        mysql::db { 'spec1':
          user     => 'root1',
          password => 'password',
        }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)

      expect(shell("mysql -e 'show databases;'|grep spec1").exit_code).to be_zero
    end
  end

  describe 'creating a database with post-sql' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      pp = <<-EOS
        class { 'mysql::server': override_options => { 'root_password' => 'password' } }
        file { '/tmp/spec.sql':
          ensure  => file,
          content => 'CREATE TABLE table1 (id int);',
          before  => Mysql::Db['spec2'],
        }
        mysql::db { 'spec2':
          user     => 'root1',
          password => 'password',
          sql      => '/tmp/spec.sql',
        }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    it 'should have the table' do
      expect(shell("mysql -e 'show tables;' spec2|grep table1").exit_code).to be_zero
    end
  end

  describe 'creating a database with dbname parameter' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      pp = <<-EOS
        class { 'mysql::server': override_options => { 'root_password' => 'password' } }
        mysql::db { 'spec1':
          user     => 'root1',
          password => 'password',
          dbname   => 'realdb',
        }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    it 'should have the database named realdb' do
      expect(shell("mysql -e 'show databases;'|grep realdb").exit_code).to be_zero
    end
  end

  describe 'creating a database with empty user password' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      pp = <<-EOS
        class { 'mysql::server': override_options => { 'root_password' => 'password' } }
        mysql::db { 'spec3':
          user     => 'root3',
          password => '',
        }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    it 'should have an empty password' do
      shell("mysql -NBe \"show grants for root3@localhost\"") do |r|
        expect(r.stdout).not_to match(/IDENTIFIED BY/)
        expect(r.stderr).to be_empty
      end
    end
  end
end
