module Scm::Adapters
	class SvnAdapter < AbstractAdapter

		# Some explanation is in order about "chaining."
		#
		# First, realize that a base SvnAdapter only tracks the history of a single
		# subdirectory. If you point an adapter at /trunk, then that adapter is
		# going to ignore eveything in /branches and /tags.
		#
		# The problem with this is that directories often get moved about.  What is
		# called "/trunk" today might have been in a branch directory at some point
		# in the past. But since we completely ignore other directories, we never see
		# that old history.
		#
		# Suppose for example that from revisions 1 to 100, development occured in
		# /branches/beta. Then at revision 101, /trunk was created by copying
		# /branches/beta, and this /trunk lives on to this day.
		#
		# The log for revision 101 is going to look something like this:
		#
		# Changed paths:
		#    D /branches/beta
		#    A /trunk (from /branches/beta:100)
		#
		# A single SvnAdapter pointed at today's /trunk will only see revisions 101
		# to HEAD, because /trunk didn't even exist before revision 101.
		#
		# To capture the prior history, we need to create *another* SvnAdapter
		# which points at /branches/beta, and which considers revisions from 1 to 100.
		#
		# That's what chaining is: when we find that the first commit of an adapter
		# indicates the wholesale renaming or copying of the entire tree from
		# another location, then we generate a new SvnAdapter that points to that
		# prior location, and process that SvnAdapter as well.
		#
		# This behavior recurses ("chains") all the way back to revision 1.
		#
		# It only works if the *entire branch* changes names. We don't chain when
		# subdirectories or individual files are copied.

		# Returns the entire parent ancestry chain as a simple array.
		def chain
			(parent_svn ? parent_svn.chain : []) << self
		end

		# If this adapter's branch was created by copying or renaming another branch,
		# then return a new adapter that points to that prior branch.
		def parent_svn(since=0)
			parent = nil
			c = first_commit(since)
			if c
				c.diffs.each do |d|
					if d.action == 'A' && d.path == branch_name && d.from_path && d.from_revision
						parent = SvnAdapter.new(:url => File.join(root, d.from_path),
													 :username => username, :password => password, 
													 :branch_name => d.from_path, :final_token => d.from_revision).normalize
						break
					end
				end
			end
			parent
		end

		#------------------------------------------------------------------
		# Recursive or "chained" versions of the commit accessors.
		#
		# These methods recurse through the chain of ancestors for this
		# adapter, calling the base_* method in turn for each ancestor.
		#------------------------------------------------------------------

		# Returns the count of commits following revision number 'since'.
		def chained_commit_count(since=0)
			(parent_svn ? parent_svn.chained_commit_count(since) : 0) + base_commit_count(since)
		end

		# Returns an array of revision numbers for all commits following revision number 'since'.
		def chained_commit_tokens(since=0)
			(parent_svn ? parent_svn.chained_commit_tokens(since) : []) + base_commit_tokens(since)
		end

		# Returns an array of commits following revision number 'since'.
		def chained_commits(since=0)
			(parent_svn ? parent_svn.chained_commits(since) : []) + base_commits(since)
		end

		# Yield verbose commits following revision number 'since', one at a time.
		def chained_each_commit(since=0, &block)
			parent_svn.chained_each_commit(since, &block) if parent_svn
			base_each_commit(since) do |commit|
				block.call commit
			end
		end

		# Helper methods for parent_svn

		def first_token(since=0)
			first_commit(since).token
		end

		def first_commit(since=0)
			Scm::Parsers::SvnXmlParser.parse(next_revision_xml(since)).first
		end
	
		# Returns the first commit with a revision number greater than the provided revision number
		def next_revision_xml(since)
			run "svn log --verbose --xml --stop-on-copy -r #{since+1}:#{final_token || 'HEAD'} --limit 1 #{opt_auth} '#{SvnAdapter.uri_encode(File.join(self.root, self.branch_name))}@#{final_token || 'HEAD'}'"
		end
	end
end
