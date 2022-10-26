	if ($] lt 5.010000) {
		$meta->{prereqs}{runtime}{requires}{'MRO::Compat'} = 0;
	}
	if ($] lt 5.014000) {
		$meta->{prereqs}{runtime}{requires}{'Devel::GlobalDestruction'} = 0;
	}
