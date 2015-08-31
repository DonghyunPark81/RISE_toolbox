%% housekeeping
close all
home()
%% Choose a model type: see cell "create the structural VAR model" below
model_type=2;

%% Create dataset
do_plot=true;

[db,varlist]=create_dataset(do_plot);

%% Create the structural VAR model
close()

% first we create a template structure
% ------------------------------------
tpl=svar.template();

% we update the fields of the structure
% --------------------------------------
tpl.endogenous=varlist;
tpl.nlags=2;

% create restrictions on parameters as well as markov chains
%------------------------------------------------------------
switch model_type
    case 0
        % constant-parameter model
        [restrictions,tpl]=create_restrictions_and_markov_chains0(tpl);
    case 1
        % Coefficients are switching regimes across all equations
        % (synchronized case) 
        [restrictions,tpl]=create_restrictions_and_markov_chains1(tpl);
    case 2
        % Coefficients and variances have different chains, different
        % regimes, and different durations 
        [restrictions,tpl]=create_restrictions_and_markov_chains2(tpl);
    case 3
        % Only coefficients in monetary policy equation are changing
        [restrictions,tpl]=create_restrictions_and_markov_chains3(tpl);
    case 4
        % Only variance in monetary policy equation is changing
        [restrictions,tpl]=create_restrictions_and_markov_chains4(tpl);
    case 5
        % Both coefficients and variances in monetary policy equation
        % change with two independent Markov processes 
        [restrictions,tpl]=create_restrictions_and_markov_chains5(tpl);
    otherwise
        error('the coded model types are 0, 1, 2, 3, 4 and 5')
end

% finally we create a svar object by pushing the structure into svar
%--------------------------------------------------------------------
m=svar(tpl,'data',db,'estim_linear_restrictions',restrictions);

%% Find posterior mode

mest=estimate(m,'estim_start_date','1960Q1');

%% Markov chain Monte Carlo
% Note that because of the linear restrictions, not all parameters are
% estimated. Hence, the effective number of estimated parameters is smaller
% than the number of parameters declared by the user. This is reflected in
% the dimensions of lb,ub,x0 and SIG below. The user does not have to be
% concerned about those.
[objective,lb,ub,x0,SIG]=pull_objective(mest);

ndraws_mcmc         = 1500;  % number of parameter draws through MCMC.
ndraws_burnin       = floor(0.1*ndraws_mcmc); % number of parameter draws to be burned
mcmc_options=struct('burnin',ndraws_burnin,'N',ndraws_mcmc,'thin',1);

Results=mh_sampler(objective,lb,ub,mcmc_options,x0,SIG);

%% Marginal data density
% pick yours: 'bridge','mhm','mueller','swz','is','ris','cj'

log_mdd = mcmc_mdd(Results.pop,lb,ub,...
    struct('log_post_kern',objective,... % function to MINIMIZE !!!
    'algorithm','swz',... % MDD algorithm
    'L',500 ... % Number of IID draws
));

%% Impulse responses
myirfs=irf(mest);

%% Out-of sample forecasts at the mode

mycast=forecast(mest);

%% Conditional forecast on ygap: parameter uncertainty only...
ndraws=200;
plot_cf=true;
cbands=[10,20,50,80,90];
[fkst,bands,hdl]=do_conditional_forecasts(mest,db,Results.pop,ndraws,cbands,plot_cf);

