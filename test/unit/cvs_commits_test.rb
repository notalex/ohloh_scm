require_relative '../test_helper'

module Scm::Adapters
	class CvsCommitsTest < Scm::Test

		def test_commits
			with_cvs_repository('cvs', 'simple') do |cvs|

				assert_equal ['2006/06/29 16:21:07',
											'2006/06/29 18:14:47',
											'2006/06/29 18:45:29',
											'2006/06/29 18:48:54',
											'2006/06/29 18:52:23'], cvs.commits.collect { |c| c.token }

				assert_equal ['2006/06/29 18:48:54',
											'2006/06/29 18:52:23'],
					cvs.commits(:after => '2006/06/29 18:45:29').collect { |c| c.token }

				# Make sure we are date format agnostic (2008/01/01 is the same as 2008-01-01)
				assert_equal ['2006/06/29 18:48:54',
											'2006/06/29 18:52:23'],
					cvs.commits(:after => '2006-06-29 18:45:29').collect { |c| c.token }

				assert_equal [], cvs.commits(:after => '2006/06/29 18:52:23').collect { |c| c.token }
			end
		end

		def test_commits_sets_scm
			with_cvs_repository('cvs', 'simple') do |cvs|
				cvs.commits.each do |c|
					assert_equal cvs, c.scm
				end
			end
		end

    def test_commits_valid_encoding
      # TODO: Replace with local repository.
      cvs = Scm::Adapters::CvsAdapter.new(url: ':pserver:anonymous:@vrecognition.cvs.sourceforge.net:/cvsroot/vrecognition', module_name: 'vrecognition')

      assert_nothing_raised do
        cvs.commits
      end
    end
	end
end
