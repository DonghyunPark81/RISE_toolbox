function [T,R,Z,H,Q,sstate,init]=state_space_wrapper(syst)

T=zeros(syst.m);

T(:,syst.state_vars_location)=syst.Tx{1};

R=syst.Te{1};

init=struct('a',syst.a{1},'P',syst.P{1});

Z=syst.obs_id;

H=syst.H{1};

if isempty(H)
    
    H=zeros(numel(Z));
    
end

Q=eye(size(R,2));

sstate=syst.steady_state{1};

end