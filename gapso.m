clc;
clear;
close all;

%% Problem Definition

CostFunction=@Sphere;       % Cost Function

nVar=10;                    % Number of Variables

VarSize=[1 nVar];           % Size of Variables Matrix

VarMin=-5;                  % Lower Bound of Variables
VarMax= 5;                  % Upper Bound of Variables

VarRange=[VarMin VarMax];   % Variation Range of Variables

VelMax=(VarMax-VarMin)/10;  % Maximum Velocity
VelMin=-VelMax;             % Minimum Velocity

%% PSO-GA Parameters

MaxIt=100;          % Maximum Number of Iterations

MaxSubItGA=5;       % Maximum Number of Sub-Iterations for GA

MaxSubItPSO=10;     % Maximum Number of Sub-Iterations for PSO

nPop=50;            % Swarm (Population) Size

% Definition of Constriction Coefficients
phi1=2.05;
phi2=2.05;
phi=phi1+phi2;
chi=2/(phi-2+sqrt(phi^2-4*phi));

w=chi;
c1=phi1*chi;
c2=phi2*chi;

pCrossover=0.7;                         % Crossover Percentage
nCrossover=round(pCrossover*nPop/2)*2;  % Number of Parents (Offsprings)

pMutation=0.2;                      % Mutation Percentage
nMutation=round(pMutation*nPop);    % Number of Mutants


%% Initialization

% Empty Structure to Hold Individuals Data
empty_individual.Position=[];
empty_individual.Velocity=[];
empty_individual.Cost=[];
empty_individual.Best.Position=[];
empty_individual.Best.Cost=[];

% Create Population Matrix
pop=repmat(empty_individual,nPop,1);

% Global Best
BestSol.Cost=inf;

% Initialize Positions
for i=1:nPop
    
    pop(i).Position=unifrnd(VarMin,VarMax,VarSize);
    pop(i).Velocity=zeros(VarSize);
    
    pop(i).Cost=CostFunction(pop(i).Position);
    
    pop(i).Best.Position=pop(i).Position;
    pop(i).Best.Cost=pop(i).Cost;
    
    if pop(i).Best.Cost<BestSol.Cost
        BestSol=pop(i).Best;
    end
    
end

% Sort Population
pop=SortPopulation(pop);

% Vector to Hold Best Cost Values
BestCost=zeros(MaxIt,1);

%% PSO-GA Main Loop

for it=1:MaxIt
    
    % GA Operators
    for gait=1:MaxSubItGA
        % Crossover
        popc=repmat(empty_individual,nCrossover/2,2);
        for k=1:nCrossover/2

            i1=randi([1 nPop]);
            i2=randi([1 nPop]);

            p1=pop(i1);
            p2=pop(i2);

            [popc(k,1).Position popc(k,2).Position]=Crossover(p1.Position,p2.Position,VarRange);

            popc(k,1).Cost=CostFunction(popc(k,1).Position);
            popc(k,2).Cost=CostFunction(popc(k,2).Position);

            if p1.Best.Cost<p2.Best.Cost
                popc(k,1).Best=p1.Best;
                popc(k,2).Best=p1.Best;
            else
                popc(k,1).Best=p2.Best;
                popc(k,2).Best=p2.Best;
            end

            if rand<0.5
                popc(k,1).Velocity=p1.Velocity;
                popc(k,2).Velocity=p2.Velocity;
            else
                popc(k,1).Velocity=p2.Velocity;
                popc(k,2).Velocity=p1.Velocity;
            end

        end
        popc=popc(:);


        % Mutation
        popm=repmat(empty_individual,nMutation,1);
        for k=1:nMutation

            i=randi([1 nPop]);

            p=pop(i);

            popm(k).Position=Mutate(p.Position,VarRange);

            popm(k).Cost=CostFunction(popm(k).Position);

            popm(k).Velocity=p.Velocity;

            popm(k).Best=p.Best;

        end

        % Merge Population
        pop=[pop
             popc
             popm];

        % Sort Population
        pop=SortPopulation(pop);

        % Delete Extra Individuals
        pop=pop(1:nPop);

        for i=1:nPop

            % Update Personal Best
            if pop(i).Cost<pop(i).Best.Cost

                pop(i).Best.Position=pop(i).Position;
                pop(i).Best.Cost=pop(i).Cost;

                % Update Global Best
                if pop(i).Best.Cost<BestSol.Cost
                    BestSol=pop(i).Best;
                end

            end

        end    
    end
    
    % PSO Operators
    for psoit=1:MaxSubItPSO
        for i=1:nPop

            % Update Velocity
            pop(i).Velocity=w*pop(i).Velocity ...
                + c1*rand(VarSize).*(pop(i).Best.Position-pop(i).Position) ...
                + c2*rand(VarSize).*(BestSol.Position-pop(i).Position);

            % Apply Velocity Bounds
            pop(i).Velocity=min(max(pop(i).Velocity,VelMin),VelMax);

            % Update Position
            pop(i).Position=pop(i).Position+pop(i).Velocity;

            % Velocity Reflection
            flag=(pop(i).Position<VarMin | pop(i).Position>VarMax);
            pop(i).Velocity(flag)=-pop(i).Velocity(flag);

            % Apply Position Bounds
            pop(i).Position=min(max(pop(i).Position,VarMin),VarMax);

            % Evaluation
            pop(i).Cost=CostFunction(pop(i).Position);

            % Update Personal Best
            if pop(i).Cost<pop(i).Best.Cost

                pop(i).Best.Position=pop(i).Position;
                pop(i).Best.Cost=pop(i).Cost;

                % Update Global Best
                if pop(i).Best.Cost<BestSol.Cost
                    BestSol=pop(i).Best;
                end

            end

        end
    end
    
    % Store Best Cost
    BestCost(it)=BestSol.Cost;
    
    % Show Iteration Information
    disp(['Iteration ' num2str(it) ': Best Cost = ' num2str(BestCost(it))]);
    
end

%% Plots

figure;
semilogy(BestCost);

