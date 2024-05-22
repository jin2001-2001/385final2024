#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

#define MAP_HEIGHT 13
#define MAP_WIDTH 18
#define OBSTACLE -1

typedef struct
{
    int x, y;
} Point;

typedef struct Node
{
    Point point;
    struct Node *next;
} Node;

typedef struct
{
    Node *front;
    Node *rear;
} Queue;

void enqueue(Queue *q, Point p)
{
    Node *temp = (Node *)malloc(sizeof(Node));
    temp->point = p;
    temp->next = NULL;
    if (q->rear == NULL)
    {
        q->front = q->rear = temp;
        return;
    }
    q->rear->next = temp;
    q->rear = temp;
}

Point dequeue(Queue *q)
{
    if (q->front == NULL)
    {
        Point p = {-1, -1};
        return p;
    }
    Node *temp = q->front;
    Point p = temp->point;
    q->front = q->front->next;
    if (q->front == NULL)
    {
        q->rear = NULL;
    }
    free(temp);
    return p;
}

int is_empty(Queue *q)
{
    return q->front == NULL;
}

int is_valid(int x, int y, int map[MAP_HEIGHT][MAP_WIDTH], int visited[MAP_HEIGHT][MAP_WIDTH])
{
    return (x >= 0 && x < MAP_HEIGHT && y >= 0 && y < MAP_WIDTH && map[x][y] != OBSTACLE && !visited[x][y]);
}

int bfs(Point start, Point goal, int map[MAP_HEIGHT][MAP_WIDTH], Point *next_step)
{
    int visited[MAP_HEIGHT][MAP_WIDTH] = {0};
    int directions[4][2] = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};
    int distance[MAP_HEIGHT][MAP_WIDTH] = {0}; // Store distance from start
    Point parent[MAP_HEIGHT][MAP_WIDTH];
    Queue q = {NULL, NULL};

    enqueue(&q, start);
    visited[start.x][start.y] = 1;
    parent[start.x][start.y] = start;

    while (!is_empty(&q))
    {
        Point current = dequeue(&q);

        for (int i = 0; i < 4; i++)
        {
            int new_x = current.x + directions[i][0];
            int new_y = current.y + directions[i][1];

            if (is_valid(new_x, new_y, map, visited))
            {
                visited[new_x][new_y] = 1;
                distance[new_x][new_y] = distance[current.x][current.y] + 1;
                Point next_point = {new_x, new_y};
                parent[new_x][new_y] = current;
                enqueue(&q, next_point);

                if (new_x == goal.x && new_y == goal.y)
                {
                    Point step = goal;
                    while (!(parent[step.x][step.y].x == start.x && parent[step.x][step.y].y == start.y))
                    {
                        step = parent[step.x][step.y];
                    }
                    *next_step = step;
                    return distance[new_x][new_y]; // Return path length
                }
            }
        }
    }
    return 0; // Path not found
}


// here, input MonsterNext is an int * array which is also the output of this function, as the array of next step (0~3) for monsters to take
void MonsterNextStep(int *PlayersX, int *PlayersY, int num_players, int *MonstersX, int *MonstersY, int num_monsters, int map[MAP_HEIGHT][MAP_WIDTH], int *MonsterNext)
{
    for (int i = 0; i < num_monsters; i++)
    {
        Point monster = {MonstersX[i], MonstersY[i]};
        int shortest_path = INT_MAX;
        Point best_next_step = {-1, -1};

        for (int j = 0; j < num_players; j++)
        {
            Point player = {PlayersX[j], PlayersY[j]};
            Point next_step;
            int path_length = bfs(monster, player, map, &next_step);

            if (path_length && path_length < shortest_path)
            {
                shortest_path = path_length;
                best_next_step = next_step;
            }
        }

        if (best_next_step.x == monster.x - 1 && best_next_step.y == monster.y)
        {
            MonsterNext[i] = 0; // Up
        }
        else if (best_next_step.x == monster.x + 1 && best_next_step.y == monster.y)
        {
            MonsterNext[i] = 1; // Down
        }
        else if (best_next_step.x == monster.x && best_next_step.y == monster.y - 1)
        {
            MonsterNext[i] = 2; // Left
        }
        else if (best_next_step.x == monster.x && best_next_step.y == monster.y + 1)
        {
            MonsterNext[i] = 3; // Right
        }
        else
        {
            MonsterNext[i] = -1; // No valid move
        }
    }
}

int main()
{
    int map[MAP_HEIGHT][MAP_WIDTH] = {
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, OBSTACLE, OBSTACLE, OBSTACLE, 0, 0, 0, 0, 0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0, 0, OBSTACLE, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}};

    int PlayersX[2] = {2, 10};
    int PlayersY[2] = {2, 2};
    int MonstersX[5] = {0, 2, 10, 5, 7};
    int MonstersY[5] = {0, 0, 4, 2, 2};
    int MonsterNext[5];

    MonsterNextStep(PlayersX, PlayersY, 2, MonstersX, MonstersY, 5, map, MonsterNext);

    for (int i = 0; i < 5; i++)
    {
        printf("Monster %d next move: %d\n", i, MonsterNext[i]);
    }

    return 0;
}
